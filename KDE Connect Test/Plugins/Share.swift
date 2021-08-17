//
//  Share.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-08-12.
//

import Foundation

class Share : Plugin {
    let PAYLOAD_PORT: Int = 1739
    
    func onDevicePackageReceived(np: NetworkPackage) -> Bool {
        print("Share plugin received something")
        if (np._Type == PACKAGE_TYPE_SHARE_INTERNAL) {
            print("Share Plugin received a valid Share package")
            if (saveFile(fileData: np._Payload, filename: np._Body["filename"] as! String)) {
                print("File \(np._Body["filename"] as! String) saved successfully")
            } else {
                print("File \(np._Body["filename"] as! String) failed to save")
            }
            return true
        }
        print("Not a share packge")
        return false
    }
    
    func sendFile(deviceId: String, fileURL: URL) -> Void {
        let device: Device = backgroundService._devices[deviceId] as! Device
        var contentToSend: Data? = nil
        var lastModifiedDate: Date? = nil
        do {
            // start/stopAccessingSecurityScopedResource() is needed otherwise we get permission errors
            fileURL.startAccessingSecurityScopedResource()
            contentToSend = try Data(contentsOf: fileURL)
            if let attibute = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]) {
                lastModifiedDate = attibute.contentModificationDate
            }
            fileURL.stopAccessingSecurityScopedResource()
        } catch {
            print("Error: \(error)")
        }
        if (contentToSend != nil && lastModifiedDate != nil) {
            let lastModifiedDateUNIXEpoche: Int = Int(lastModifiedDate!.timeIntervalSince1970)
            
            let np: NetworkPackage = NetworkPackage(type: PACKAGE_TYPE_SHARE)
            np.setObject(fileURL.lastPathComponent, forKey: "filename")
            np.setInteger(lastModifiedDateUNIXEpoche, forKey: "lastModified")
            np.setInteger(contentToSend!.count, forKey: "totalPayloadSize")
            np.setInteger(1, forKey: "numberOfFiles")
            np._PayloadTransferInfo = ["port":PAYLOAD_PORT]
            np._Payload = contentToSend
            np._PayloadSize = contentToSend!.count
            device.send(np, tag: Int(PACKAGE_TAG_SHARE))
        }
    }
    
    private func saveFile(fileData: Data, filename: String) -> Bool {
        let fileManager = FileManager.default
        do {
            let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false) // gets URL of app's document directory
            let fileURL = documentDirectory.appendingPathComponent(filename) // adds new file's name to URL
            //print(fileURL.absoluteString)
            try fileData.write(to: fileURL) // and save!
            return true
        } catch {
            print(error)
        }
        return false
    }
}
