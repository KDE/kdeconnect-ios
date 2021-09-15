//
//  Share.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-08-12.
//

import Foundation
import AVFoundation

@objc class Share : NSObject, Plugin {
    @objc let controlDevice: Device
    let MIN_PAYLOAD_PORT: Int = 1739
    let MAX_PAYLOAD_PORT: Int = 1764
    
    // Receiving
    var totalNumOfFilesToReceive: Int = 0
    var numFilesReceived: Int = 0
    
    // Sending
    var isVacant: Bool = true
    var fileDatas: [Data] = []
    var fileNames: [String] = []
    var fileLastModifiedEpochs: [Int] = []
    var totalPayloadSize: Int = 0
    var totalNumOfFiles: Int = 0
    var numFilesSuccessfullySent: Int = 0
    
    @objc init (controlDevice: Device) {
        self.controlDevice = controlDevice
    }
    
    @objc func onDevicePackageReceived(np: NetworkPackage) -> Bool {
        print("Share plugin received something")
        if (np._Type == PACKAGE_TYPE_SHARE) {
            print("Share Plugin received a valid Share package")
            if (numFilesReceived == 0) {
                totalNumOfFilesToReceive = np.integer(forKey: "numberOfFiles")
            }
            if (saveFile(fileData: np._Payload, filename: np._Body["filename"] as! String)) {
                //connectedDevicesViewModel.showFileReceivedAlert()
                print("File \(np._Body["filename"] as! String) saved successfully")
                numFilesReceived += 1
            } else {
                print("File \(np._Body["filename"] as! String) failed to save")
            }
            if (numFilesReceived == totalNumOfFilesToReceive) {
                AudioServicesPlaySystemSound(soundMailReceived)
                numFilesReceived = 0
                totalNumOfFilesToReceive = 0
            }
            return true
        }
        print("Not a share packge")
        return false
    }
    
    @objc private func resetTransferData() -> Void {
        fileDatas = []
        fileNames = []
        fileLastModifiedEpochs = []
        totalPayloadSize = 0
        totalNumOfFiles = 0
        numFilesSuccessfullySent = 0
    }
    
    @objc func prepAndInitFileSend(fileURLs: [URL]) -> Void {
        if (isVacant) {
            isVacant = false
            for url in fileURLs {
                var contentToSend: Data? = nil
                var lastModifiedDate: Date? = nil
                do {
                    // start/stopAccessingSecurityScopedResource() is needed otherwise we get permission errors
                    url.startAccessingSecurityScopedResource()
                    contentToSend = try Data(contentsOf: url)
                    if let attibute = try? url.resourceValues(forKeys: [.contentModificationDateKey]) {
                        lastModifiedDate = attibute.contentModificationDate
                    }
                    url.stopAccessingSecurityScopedResource()
                } catch {
                    print("Error reading file on device: \(error)")
                }
                if (contentToSend != nil && lastModifiedDate != nil) {
                    fileDatas.append(contentToSend!)
                    fileNames.append(url.lastPathComponent)
                    fileLastModifiedEpochs.append(Int(lastModifiedDate!.millisecondsSince1970))
                    totalPayloadSize += contentToSend!.count
                }
            }
            totalNumOfFiles = fileDatas.count
            sendSinglePayload()
        } else {
            print("Share plugin busy for this device, ignoring sharing attempt")
            AudioServicesPlaySystemSound(soundAudioToneBusy)
        }
    }
    
    @objc func sendSinglePayload() -> Void {
        if ((fileDatas.count == fileNames.count) && (fileDatas.count == fileLastModifiedEpochs.count) && totalPayloadSize > 0 && fileDatas.count > 0 && (numFilesSuccessfullySent < totalNumOfFiles)) {
            let np: NetworkPackage = NetworkPackage(type: PACKAGE_TYPE_SHARE)
            np.setObject(fileNames.first, forKey: "filename")
            np.setInteger(fileLastModifiedEpochs.first!, forKey: "lastModified")
            np.setInteger(totalPayloadSize, forKey: "totalPayloadSize")
            np.setInteger(totalNumOfFiles, forKey: "numberOfFiles")
            np._PayloadTransferInfo = ["port":MIN_PAYLOAD_PORT]
            np._Payload = fileDatas.first
            np._PayloadSize = fileDatas.first!.count
            controlDevice.send(np, tag: Int(PACKAGE_TAG_SHARE))
            fileDatas.removeFirst()
            fileNames.removeFirst()
            fileLastModifiedEpochs.removeFirst()
            numFilesSuccessfullySent += 1
            //AudioServicesPlaySystemSound(soundMailSent)
        } else {
            print("Finished sending a batch of \(totalNumOfFiles) files")
            AudioServicesPlaySystemSound(soundMailSent)
            isVacant = true
            resetTransferData()
        }
    }
    
    @objc private func saveFile(fileData: Data, filename: String) -> Bool {
        let fileManager = FileManager.default
        do {
            let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false) // gets URL of app's document directory
            let fileURL = documentDirectory.appendingPathComponent(filename) // adds new file's name to URL
            //print(fileURL.absoluteString)
            try fileData.write(to: fileURL) // and save!
            return true
        } catch {
            print("Error saving file to device \(error)")
        }
        return false
    }
}
