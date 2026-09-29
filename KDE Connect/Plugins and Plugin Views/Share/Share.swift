/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 *                         2023 Apollo Zhu <public-apollonian@outlook.com>
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
#if !os(macOS)
import UIKit
#else
import AppKit
#endif
import OrderedCollections
import Photos

extension Notification.Name {
    static let didReceiveFileNotification = Notification.Name("didReceiveFileNotification")
    static let failedToAddToPhotosLibrary = Notification.Name("failedToAddToPhotosLibrary")
}

@objc class Share: NSObject, ObservablePlugin {
    @objc weak var controlDevice: Device!
    
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
    
    @objc func onDevicePacketReceived(np: NetworkPacket) {
        logger.debug("Share plugin received something")
        
        if (np.type == .shareRequestUpdate) {
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
        } else if (np.type == .share) {
            logger.debug("Share Plugin received a valid Share packet")
            if let filename = np._Body["filename"] as? String {
                guard let payloadPath = np.payloadPath else {
                    logger.fault("File \(filename, privacy: .public) missing actual file contents")
                    // FIXME: show error to UI
#if !os(macOS)
                    notificationHapticsGenerator.notificationOccurred(.error)
#endif
                    return
                }
                Task {
                    do {
                        try await save(payloadPath, as: filename, for: np)
                        // connectedDevicesViewModel.showFileReceivedAlert()
                        logger.debug("File \(filename, privacy: .private(mask: .hash)) saved successfully")
#if !os(macOS)
                        await notificationHapticsGenerator.notificationOccurred(.success)
#endif
                    } catch {
                        logger.fault("File \(filename, privacy: .public) failed to save due to \(error.localizedDescription, privacy: .public)")
                        await MainActor.run {
                            filesFailedToReceive.append(.init(
                                path: payloadPath,
                                name: filename,
                                error: error,
                                countOtherFailedFilesInTheSameTransfer: 0
                            ))
#if !os(macOS)
                            notificationHapticsGenerator.notificationOccurred(.error)
#endif
                        }
                    }
                    await MainActor.run {
                        currentFilesReceiving[payloadPath] = nil
                        bumpNumFilesReceived()
                    }
                }
            } else if let sharedText = np._Body["text"] as? String {
                // Text sharing: copy to clipboard
#if !os(macOS)
                UIPasteboard.general.string = sharedText
#else
                NSPasteboard.general.setString(sharedText, forType: .string)
#endif
            } else if let sharedURLText = np._Body["url"] as? String {
                // TODO: avoid to handle URL open in the share extension
                // URL sharing: open it through URL scheme
                if let sharedURL = URL(string: sharedURLText) {
                    DispatchQueue.main.async {
#if !os(macOS)
                        UIApplication.shared.open(sharedURL)
#else
                        NSWorkspace.shared.open(sharedURL)
#endif
                    }
                }
            } else {
                logger.fault("Nil received when trying to parse filename")
#if !os(macOS)
                notificationHapticsGenerator.notificationOccurred(.error)
#endif
            }
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
                    .creationDateKey,
                    .contentModificationDateKey,
                    .fileSizeKey,
                ])
                let filename = url.lastPathComponent
                guard let fileSize = attributes.fileSize else {
                    logger.fault("Unable to read size of \(filename, privacy: .public), skipping")
#if !os(macOS)
                    notificationHapticsGenerator.notificationOccurred(.error)
#endif
                    continue
                }
                
                let creationDate = attributes.creationDate
                if creationDate == nil {
                    logger.error("Unable to read creation time of \(filename, privacy: .public)")
                }
                let lastModifiedDate = attributes.contentModificationDate
                if lastModifiedDate == nil {
                    logger.error("Unable to read last modified time of \(filename, privacy: .public)")
                }
                newFiles.append(FileTransferItemInfo(
                    path: url,
                    name: filename,
                    creationEpoch: creationDate?.millisecondsSince1970,
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
            let np = NetworkPacket(type: .shareRequestUpdate)
            np.setInteger(totalNumOfFilesToSend, forKey: "numberOfFiles")
            np.setInteger(totalPayloadSize, forKey: "totalPayloadSize")
            controlDevice.send(np, tag: Int(PACKET_TAG_SHARE))
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
#if !os(macOS)
                    notificationHapticsGenerator.notificationOccurred(.error)
#endif
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
        let info = payload.info
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            // Don't resurrect a file that has already finished or was reset after a failure.
            guard let previous = self.currentFilesSending[info.path] else { return }
            self.currentFilesSending[info.path] = info
            if previous.totalBytesCompleted == 0 && info.totalBytesCompleted > 0 {
                // The remote has connected to this file's payload socket and data
                // is flowing: announce the next file now so its connection setup
                // overlaps with this transfer instead of happening after it.
                self.sendSinglePayload()
            }
        }
    }
    
    func onPacket(_ np: NetworkPacket, sentWithPacketTag packetTag: Int) {
        guard packetTag == PACKET_TAG_PAYLOAD else { return }
        guard let path = np.payloadPath else {
            logger.fault("Cannot remove file for \(np) after successfully sent")
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            if self.currentFilesSending.removeValue(forKey: path) != nil {
                self.numFilesSuccessfullySent += 1
#if !os(macOS)
                notificationHapticsGenerator.notificationOccurred(.success)
#endif
                self.sendSinglePayload()
            } else {
                self.logger.fault("Sent \(np) not currently sending")
            }
        }
    }
    
    func onPacket(_ np: NetworkPacket, sendWithPacketTag packetTag: Int, failedWithError error: Error) {
        guard packetTag == PACKET_TAG_PAYLOAD else { return }

        guard let path = np.payloadPath else {
            logger.fault("Cannot remove file for \(np) after failed to send with \(error)")
            return
        }
        DispatchQueue.main.async { [weak self, logger] in
            guard let self else { return }
            
            guard let file = self.currentFilesSending.removeValue(forKey: path) else {
                // Not part of the current batch (e.g. a stray callback for a file of an earlier,
                // already aborted batch), don't reset whatever is being sent now.
                logger.fault("Cannot find info for \(np) after failed to send with \(error)")
                return
            }
            let remaining = self.totalNumOfFilesToSend - self.numFilesSuccessfullySent - 1
            self.filesFailedToSend.append(FailedFileTransferItemInfo(
                path: file.path,
                name: file.name,
                error: error,
                countOtherFailedFilesInTheSameTransfer: remaining
            ))
#if !os(macOS)
            notificationHapticsGenerator.notificationOccurred(.error)
#endif
            self.resetTransferData()
        }
    }
    
    /// Maximum number of files announced to the remote device at once.
    private static let maxFilesInFlight = 2
    
    /// Whether another file can be announced right now.
    ///
    /// Only one file may be waiting for its payload connection at a time,
    /// because `LanLink` pairs incoming payload connections with pending files
    /// in the order the files were announced.
    private var canAnnounceAnotherFile: Bool {
        currentFilesSending.count < Self.maxFilesInFlight
        && currentFilesSending.values.allSatisfy { $0.totalBytesCompleted > 0 }
    }
    
    @objc func sendSinglePayload() {
        if totalPayloadSize > 0,
           !filesToSend.isEmpty,
           numFilesSuccessfullySent < totalNumOfFilesToSend {
            guard canAnnounceAnotherFile else { return }
            let currentFile = filesToSend.removeFirst()
            currentFilesSending[currentFile.path] = currentFile
            
            let np = NetworkPacket(type: .share)
            np.setObject(currentFile.name, forKey: "filename")
            if let creationTime = currentFile.creationEpoch {
                np.setObject(creationTime as NSNumber, forKey: "creationTime")
            }
            if let lastModified = currentFile.lastModifiedEpoch {
                np.setObject(lastModified as NSNumber, forKey: "lastModified")
            }
            np.setInteger(totalPayloadSize, forKey: "totalPayloadSize")
            np.setInteger(totalNumOfFilesToSend, forKey: "numberOfFiles")
            np.payloadPath = currentFile.path
            np._PayloadSize = currentFile.totalBytes ?? -1
            controlDevice.send(np, tag: Int(PACKET_TAG_SHARE))
        } else if currentFilesSending.isEmpty {
            logger.debug("Finished sending a batch of \(self.totalNumOfFilesToSend) files")
            SystemSound.mailSent.play()
            resetTransferData()
        }
    }
    
    private func save(_ url: URL, as filename: String, for np: NetworkPacket) async throws {
        func add(as type: PHAssetResourceType) async throws {
            do {
                try await PHPhotoLibrary.shared().performChanges {
                    let request = PHAssetCreationRequest.forAsset()
                    let options = PHAssetResourceCreationOptions()
                    options.originalFilename = filename
                    if let creationTime = np._Body["creationTime"] as? Int64 {
                        request.creationDate = Date(milliseconds: creationTime)
                    } else if let lastModified = np._Body["lastModified"] as? Int64 {
                        request.creationDate = Date(milliseconds: lastModified)
                    }
                    request.addResource(with: type, fileURL: url, options: options)
                }
                do {
                    try FileManager.default.removeItem(at: url)
                } catch {
                    logger.error("Can't delete file at \(url)")
                }
            } catch {
                logger.error("Can't save to photos library due to \(error)")
                NotificationCenter.default.post(name: .failedToAddToPhotosLibrary, object: nil)
                try _saveFile(url, as: filename, for: np)
            }
        }
        
        if PHPhotoLibrary.mayAllowAdd,
           let type = UTType(filenameExtension: (filename as NSString).pathExtension) {
            if type.conforms(to: .image),
               KdeConnectSettings.shared.savePhotosToPhotosLibrary {
                try await add(as: .photo)
                return
            } else if type.conforms(to: .movie),
                      KdeConnectSettings.shared.saveVideosToPhotosLibrary {
                try await add(as: .video)
                return
            }
        }
        
        try _saveFile(url, as: filename, for: np)
    }
    
    private func _saveFile(_ url: URL, as filename: String, for np: NetworkPacket) throws {
        let fileManager = FileManager.default
        let directory = try URL.defaultDestinationDirectory
        let fileURL = FilesHelper.findNonExistingName(for: filename, at: directory)
        logger.debug("\(fileURL.absoluteString, privacy: .private(mask: .hash))")
        try fileManager.moveItem(at: url, to: fileURL) // and save!
        
        var attributes = [FileAttributeKey: Any]()
        if let creationTime = np._Body["creationTime"] as? Int64 {
            attributes[.creationDate] = Date(milliseconds: creationTime)
        }
        if let lastModified = np._Body["lastModified"] as? Int64 {
            attributes[.modificationDate] = Date(milliseconds: lastModified)
        }
        try fileManager.setAttributes(attributes, ofItemAtPath: fileURL.path)
    }
}

extension PHPhotoLibrary {
    static var mayAllowAdd: Bool {
        switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
        case .notDetermined, .authorized, .limited:
            return true
        case .restricted, .denied:
            return false
        @unknown default:
            return true
        }
    }
}
