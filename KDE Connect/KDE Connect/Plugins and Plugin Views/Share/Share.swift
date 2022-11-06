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
    var files: [File] = []
    var totalPayloadSize: Int = 0
    var totalNumOfFiles: Int = 0
    var numFilesSuccessfullySent: Int = 0
    
    struct File {
        let path: URL
        let name: String
        let lastModifiedEpoch: Int64
        let size: Int
    }
    
    private let logger = Logger()
    
    @objc init (controlDevice: Device) {
        self.controlDevice = controlDevice
    }
    
    @objc func onDevicePackageReceived(np: NetworkPackage) -> Bool {
        logger.debug("Share plugin received something")
        if (np.type == .share) {
            logger.debug("Share Plugin received a valid Share package")
            if (numFilesReceived == 0) {
                totalNumOfFilesToReceive = np.integer(forKey: "numberOfFiles")
            }
            if let filename = np._Body["filename"] as? String {
                guard let payloadPath = np.payloadPath else {
                    logger.fault("File \(filename, privacy: .public) missing actual file contents")
                    notificationHapticsGenerator.notificationOccurred(.error)
                    return true
                }
                if saveFile(payloadPath, as: filename) {
                    //connectedDevicesViewModel.showFileReceivedAlert()
                    logger.debug("File \(filename, privacy: .private(mask: .hash)) saved successfully")
                    numFilesReceived += 1
                    notificationHapticsGenerator.notificationOccurred(.success)
                } else {
                    logger.fault("File \(filename, privacy: .public) failed to save")
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
                logger.fault("Nil received when trying to parse filename")
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
        logger.debug("Not a share package")
        return false
    }
    
    @objc private func resetTransferData() {
        files = []
        totalPayloadSize = 0
        totalNumOfFiles = 0
        numFilesSuccessfullySent = 0
    }
    
    @objc func prepAndInitFileSend(fileURLs: [URL]) {
        if (isVacant) {
            isVacant = false
            for url in fileURLs {
                // start/stopAccessingSecurityScopedResource() is needed for files outside of sandbox;
                // otherwise we get permission errors.
                // However, it returns false for files already inside the sandbox,
                // so omitting the check here.
                _ = url.startAccessingSecurityScopedResource()
                defer { url.stopAccessingSecurityScopedResource() }
                do {
                    let attributes = try url.resourceValues(forKeys: [
                        .contentModificationDateKey,
                        .fileSizeKey
                    ])
                    guard let lastModifiedDate = attributes.contentModificationDate,
                          let fileSize = attributes.fileSize
                    else {
                        logger.fault("Missing metadata for file \(url.lastPathComponent, privacy: .public)")
                        continue
                    }
                    files.append(File(
                        path: url,
                        name: url.lastPathComponent,
                        lastModifiedEpoch: lastModifiedDate.millisecondsSince1970,
                        size: fileSize
                    ))
                    totalPayloadSize += fileSize
                } catch {
                    logger.fault("Error reading file on device: \(error.localizedDescription, privacy: .public)")
                }
            }
            totalNumOfFiles = files.count
            sendSinglePayload()
        } else {
            logger.error("Share plugin busy for this device, ignoring sharing attempt")
            SystemSound.audioToneBusy.play()
        }
    }
    
    @objc func sendSinglePayload() {
        if totalPayloadSize > 0 && !files.isEmpty && numFilesSuccessfullySent < totalNumOfFiles {
            let currentFile = files.removeFirst()
            let np = NetworkPackage(type: .share)
            np.setObject(currentFile.name, forKey: "filename")
            np.setObject(currentFile.lastModifiedEpoch as NSNumber, forKey: "lastModified")
            np.setInteger(totalPayloadSize, forKey: "totalPayloadSize")
            np.setInteger(totalNumOfFiles, forKey: "numberOfFiles")
            np._PayloadTransferInfo = ["port": MIN_PAYLOAD_PORT]
            np.payloadPath = currentFile.path
            np._PayloadSize = currentFile.size
            controlDevice.send(np, tag: Int(PACKAGE_TAG_SHARE))
            // can't really tell this here but okay:
            numFilesSuccessfullySent += 1
            notificationHapticsGenerator.notificationOccurred(.success)
        } else {
            logger.debug("Finished sending a batch of \(self.totalNumOfFiles) files")
            SystemSound.mailSent.play()
            isVacant = true
            resetTransferData()
        }
    }
    
    @objc private func saveFile(_ url: URL, as filename: String) -> Bool {
        let fileManager = FileManager.default
        do {
            let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false) // gets URL of app's document directory
            let fileURL = documentDirectory.appendingPathComponent(filename) // adds new file's name to URL
            logger.debug("\(fileURL.absoluteString, privacy: .private(mask: .hash))")
            try fileManager.moveItem(at: url, to: fileURL) // and save!
            // FIXME: set file metadata transferred through network package
            return true
        } catch {
            logger.fault("Error saving file to device \(error.localizedDescription, privacy: .public)")
        }
        return false
    }
}
