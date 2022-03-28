/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  Share.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-08-12.
//

import Foundation
import AVFoundation
import UIKit

extension Notification.Name {
    static let didReceiveFileNotification = Notification.Name("didReceiveFileNotification")
}

// TODO: Implement fallback on another port when default 1739 is unavaliable
@objc class Share : NSObject, Plugin {
    @objc weak var controlDevice: Device!
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
        if (np.type == .share) {
            print("Share Plugin received a valid Share package")
            if (numFilesReceived == 0) {
                totalNumOfFilesToReceive = np.integer(forKey: "numberOfFiles")
            }
            if let filename = np._Body["filename"] as? String {
                if saveFile(fileData: np._Payload!, filename: filename) {
                    //connectedDevicesViewModel.showFileReceivedAlert()
                    print("File \(filename) saved successfully")
                    numFilesReceived += 1
                    notificationHapticsGenerator.notificationOccurred(.success)
                } else {
                    print("File \(filename) failed to save")
                    notificationHapticsGenerator.notificationOccurred(.error)
                }
            } else if let sharedText = np._Body["text"] as? String {
                // Text sharing: copy to clipboard
                UIPasteboard.general.string = sharedText
            } else if let sharedURLText = np._Body["url"] as? String {
                // TODO: avoid to handle URL open in the share extension
                // URL sharing: open it through URL scheme
                if let sharedURL = URL(string: sharedURLText) {
                    DispatchQueue.main.async {
                        UIApplication.shared.open(sharedURL)
                    }
                }
            } else {
                print("Nil received when trying to parse filename")
                notificationHapticsGenerator.notificationOccurred(.error)
            }
            if numFilesReceived == totalNumOfFilesToReceive {
                SystemSound.mailReceived.play()
                NotificationCenter.default
                    .post(name: .didReceiveFileNotification, object: nil,
                          userInfo: nil)
                numFilesReceived = 0
                totalNumOfFilesToReceive = 0
            }
            return true
        }
        print("Not a share package")
        return false
    }
    
    @objc private func resetTransferData() {
        fileDatas = []
        fileNames = []
        fileLastModifiedEpochs = []
        totalPayloadSize = 0
        totalNumOfFiles = 0
        numFilesSuccessfullySent = 0
    }
    
    @objc func prepAndInitFileSend(fileURLs: [URL]) {
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
            SystemSound.audioToneBusy.play()
        }
    }
    
    @objc func sendSinglePayload() {
        if ((fileDatas.count == fileNames.count) && (fileDatas.count == fileLastModifiedEpochs.count) && totalPayloadSize > 0 && fileDatas.count > 0 && (numFilesSuccessfullySent < totalNumOfFiles)) {
            let np = NetworkPackage(type: .share)
            np.setObject(fileNames.first!, forKey: "filename")
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
            //SystemSound.mailSent.play()
            notificationHapticsGenerator.notificationOccurred(.success)
        } else {
            print("Finished sending a batch of \(totalNumOfFiles) files")
            SystemSound.mailSent.play()
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
