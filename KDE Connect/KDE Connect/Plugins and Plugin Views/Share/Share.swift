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
import OrderedCollections

extension Notification.Name {
    static let didReceiveFileNotification = Notification.Name("didReceiveFileNotification")
}

// TODO: Implement fallback on another port when default 1739 is unavaliable
@objc class Share : NSObject, ObservablePlugin {
    @objc weak var controlDevice: Device!
    let minPayloadPort: Int = 1739
    let maxPayloadPort: Int = 1764
    
    // Receiving
    @Published
    var totalNumOfFilesToReceive: Int = 0
    @Published
    var numFilesReceived: Int = 0
    @Published
    var currentFilesReceiving: OrderedDictionary<URL, FileTransferItemInfo> = [:]
    @Published
    var filesFailedToReceive: [FailedFileTransferItemInfo] = []
    
    // Sending
    @Published
    var filesToSend: [FileTransferItemInfo] = []
    @Published
    var currentFilesSending: OrderedDictionary<URL, FileTransferItemInfo> = [:]
    @Published
    var filesFailedToSend: [FailedFileTransferItemInfo] = []
    var totalPayloadSize: Int = 0
    @Published
    var totalNumOfFilesToSend: Int = 0
    @Published
    var numFilesSuccessfullySent: Int = 0
    
    private let logger = Logger()
    
    @objc init (controlDevice: Device) {
        self.controlDevice = controlDevice
    }
    
    @objc func onDevicePackageReceived(np: NetworkPackage) -> Bool {
        logger.debug("Share plugin received something")
        switch np.type {
        case .shareRequestUpdate:
            DispatchQueue.main.async { [weak self, logger] in
                guard let self else { return }
                if self.totalNumOfFilesToReceive > 0 {
                    let newTotal = np.integer(forKey: "numberOfFiles")
                    if newTotal > self.totalNumOfFilesToReceive {
                        self.totalNumOfFilesToReceive = newTotal
                    } else {
                        logger.debug("Updated \(newTotal) files to receive is smaller than current \(self.totalNumOfFilesToReceive), ignored")
                    }
                } else {
                    logger.debug("Received update packet but not receiving files")
                }
            }
            return true
        case .share:
            logger.debug("Share Plugin received a valid Share package")
            if let filename = np._Body["filename"] as? String {
                guard let payloadPath = np.payloadPath else {
                    logger.fault("File \(filename, privacy: .public) missing actual file contents")
                    notificationHapticsGenerator.notificationOccurred(.error)
                    return true
                }
                if saveFile(payloadPath, as: filename) {
                    //connectedDevicesViewModel.showFileReceivedAlert()
                    logger.debug("File \(filename, privacy: .private(mask: .hash)) saved successfully")
                    notificationHapticsGenerator.notificationOccurred(.success)
                } else {
                    logger.fault("File \(filename, privacy: .public) failed to save")
                    notificationHapticsGenerator.notificationOccurred(.error)
                }
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.currentFilesReceiving[payloadPath] = nil
                    self.bumpNumFilesReceived()
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
            return true
        default:
            logger.debug("Not a share package")
            return false
        }
    }
    
    private func bumpNumFilesReceived() {
        numFilesReceived += 1
        if numFilesReceived == totalNumOfFilesToReceive {
            SystemSound.mailReceived.play()
            NotificationCenter.default
                .post(name: .didReceiveFileNotification, object: nil,
                      userInfo: nil)
            numFilesReceived = 0
            totalNumOfFilesToReceive = 0
        }
    }
    
    @objc private func resetTransferData() {
        filesToSend = []
        currentFilesSending = [:]
        totalPayloadSize = 0
        totalNumOfFilesToSend = 0
        numFilesSuccessfullySent = 0
    }
    
    @objc func prepAndInitFileSend(fileURLs: [URL]) {
        let isVacant = totalNumOfFilesToSend == 0
        
        var newFiles = [FileTransferItemInfo]()
        newFiles.reserveCapacity(fileURLs.count)
        var newFilesTotalSize = 0
        
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
                    .fileSizeKey,
                ])
                guard let fileSize = attributes.fileSize else {
                    logger.fault("Unable to read size of \(url.lastPathComponent, privacy: .public), skipping")
                    notificationHapticsGenerator.notificationOccurred(.error)
                    continue
                }
                let lastModifiedDate = attributes.contentModificationDate
                if lastModifiedDate == nil {
                    logger.error("Unable to read last modified time of \(url.lastPathComponent, privacy: .public)")
                }
                newFiles.append(FileTransferItemInfo(
                    path: url,
                    name: url.lastPathComponent,
                    lastModifiedEpoch: lastModifiedDate?.millisecondsSince1970,
                    totalBytes: fileSize
                ))
                newFilesTotalSize += fileSize
            } catch {
                logger.fault("Error reading file on device: \(error.localizedDescription, privacy: .public)")
            }
        }
        filesToSend += newFiles
        totalPayloadSize += newFilesTotalSize
        totalNumOfFilesToSend += newFiles.count
        
        if isVacant {
            filesFailedToSend = []
            sendSinglePayload()
        } else {
            let np = NetworkPackage(type: .shareRequestUpdate)
            np.setInteger(totalNumOfFilesToSend, forKey: "numberOfFiles")
            np.setInteger(totalPayloadSize, forKey: "totalPayloadSize")
            controlDevice.send(np, tag: Int(PACKAGE_TAG_SHARE))
        }
    }
    
    func willReceivePayload(_ payload: FileTransferItem,
                            totalNumOfFilesToReceive: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            if self.totalNumOfFilesToReceive == 0 {
                self.filesFailedToReceive = []
            }
            
            self.currentFilesReceiving[payload.info.path] = payload.info
            if totalNumOfFilesToReceive > 0 {
                self.totalNumOfFilesToReceive = totalNumOfFilesToReceive
            } else {
                // some client like Soduto don't send numOfFiles field
                // so every single call we get means a new file to receive
                self.totalNumOfFilesToReceive += 1
            }
        }
    }
    
    func onReceivingPayload(_ payload: FileTransferItem) {
        DispatchQueue.main.async { [weak self] in
            self?.currentFilesReceiving[payload.info.path] = payload.info
        }
    }
    
    func onReceivingPayload(_ payload: FileTransferItem,
                            failedWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            let path = payload.info.path
            if self.currentFilesReceiving.removeValue(forKey: path) != nil {
                let noConcurrentJobs = self.currentFilesReceiving.isEmpty
                self.filesFailedToReceive.append(.init(
                    path: path,
                    name: payload.info.name,
                    error: error,
                    countOtherFailedFilesInTheSameTransfer: noConcurrentJobs
                    ? self.totalNumOfFilesToReceive - self.numFilesReceived - 1
                    : 0
                ))
                if noConcurrentJobs {
                    // Only 1 concurrent receiving job,
                    // cancellation cancels everything
                    notificationHapticsGenerator.notificationOccurred(.error)
                    self.numFilesReceived = 0
                    self.totalNumOfFilesToReceive = 0
                } else {
                    // Maybe we can try to receive the rest of Soduto transfers
                    self.bumpNumFilesReceived()
                }
            } else {
                self.logger.fault("Not receiving \(payload) but failed to receive with \(error)")
            }
        }
    }
    
    func onSendingPayload(_ payload: FileTransferItem) {
        DispatchQueue.main.async { [weak self] in
            self?.currentFilesSending[payload.info.path] = payload.info
        }
    }
    
    func onPackage(_ np: NetworkPackage, sentWithPackageTag packageTag: Int) {
        guard packageTag == PACKAGE_TAG_PAYLOAD else { return }
        guard let path = np.payloadPath else {
            logger.fault("Cannot remove file for \(np) after successfully sent")
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            if self.currentFilesSending.removeValue(forKey: path) != nil {
                self.numFilesSuccessfullySent += 1
                notificationHapticsGenerator.notificationOccurred(.success)
                self.sendSinglePayload()
            } else {
                self.logger.fault("Sent \(np) not currently sending")
            }
        }
    }
    
    func onPackage(_ np: NetworkPackage,
                   sendWithPackageTag packageTag: Int,
                   failedWithError error: Error) {
        guard packageTag == PACKAGE_TAG_PAYLOAD else { return }

        guard let path = np.payloadPath else {
            logger.fault("Cannot remove file for \(np) after failed to send with \(error)")
            return
        }
        DispatchQueue.main.async { [weak self, logger] in
            guard let self else { return }
            
            if let file = self.currentFilesSending.removeValue(forKey: path) {
                let remaining = self.totalNumOfFilesToSend - self.numFilesSuccessfullySent - 1
                self.filesFailedToSend.append(FailedFileTransferItemInfo(
                    path: file.path,
                    name: file.name,
                    error: error,
                    countOtherFailedFilesInTheSameTransfer: remaining
                ))
            } else {
                logger.fault("Cannot find info for \(np) after failed to send with \(error)")
            }
            notificationHapticsGenerator.notificationOccurred(.error)
            self.resetTransferData()
        }
    }
    
    @objc func sendSinglePayload() {
        if totalPayloadSize > 0,
           !filesToSend.isEmpty,
           numFilesSuccessfullySent < totalNumOfFilesToSend {
            let currentFile = filesToSend.removeFirst()
            currentFilesSending[currentFile.path] = currentFile
            
            let np = NetworkPackage(type: .share)
            np.setObject(currentFile.name, forKey: "filename")
            if let lastModified = currentFile.lastModifiedEpoch {
                np.setObject(lastModified as NSNumber, forKey: "lastModified")
            }
            np.setInteger(totalPayloadSize, forKey: "totalPayloadSize")
            np.setInteger(totalNumOfFilesToSend, forKey: "numberOfFiles")
            np._PayloadTransferInfo = ["port": minPayloadPort]
            np.payloadPath = currentFile.path
            np._PayloadSize = currentFile.totalBytes ?? -1
            controlDevice.send(np, tag: Int(PACKAGE_TAG_SHARE))
        } else if currentFilesSending.isEmpty {
            logger.debug("Finished sending a batch of \(self.totalNumOfFilesToSend) files")
            SystemSound.mailSent.play()
            resetTransferData()
        }
    }
    
    @objc private func saveFile(_ url: URL, as filename: String) -> Bool {
        let fileManager = FileManager.default
        do {
            let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false) // gets URL of app's document directory
            let fileURL = documentDirectory.appendingPathComponent(filename) // adds new file's name to URL
            logger.debug("\(fileURL.absoluteString, privacy: .private(mask: .hash))")
            switch try? fileURL.checkResourceIsReachable() {
            case true?:
                // try fileManager.removeItem(at: fileURL)
                logger.info("File already exists, skipped")
                return true
            case nil: // file doesn't eixst
                try fileManager.moveItem(at: url, to: fileURL) // and save!
            case false?: // unsupported file system
                logger.fault("incorrect url \(url, privacy: .private(mask: .hash))")
                return false
            }
            // FIXME: set file metadata transferred through network package
            return true
        } catch {
            logger.fault("Error saving file to device \(error.localizedDescription, privacy: .public)")
            return false
        }
    }
}
