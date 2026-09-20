/*
 * SPDX-FileCopyrightText: 2023 Apollo Zhu <public-apollonian@outlook.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  SetupFileTransfersForUITests.swift
//  KDE Connect
//
//  Created by Apollo Zhu on 4/29/23.
//

import Foundation
import OrderedCollections

#if DEBUG
extension UIPreview {
    // When choosing file names, think The practice of inclusive design
    // https://developer.apple.com/videos/play/wwdc2021/10275/
    static func setupFileTransfers() {
        let macBook = getSharePlugin(for: .macBook)
        let desktop = getSharePlugin(for: .desktop)
        
        // MARK: MacBook
        // All the file names appear in App Store screenshot due to device detail view
        
        macBook.currentFilesSending = makeCurrentFilesDictionary(for: [
            FileTransferItemInfo(
                path: URL(string: "file://signed.pdf")!,
                name: NSLocalizedString("signed.pdf",
                                        comment: "File name used for App Store screenshot. Here signed implies that the PDF has a written signature by someone."),
                totalBytes: 2048,
                totalBytesCompleted: 1024
            ),
        ])
        macBook.filesToSend = [
            // Live photos are sent separately as HEIC and mov files
            FileTransferItemInfo(
                path: URL(string: "file://IMG_1234.HEIC")!,
                name: NSLocalizedString("Birthday.HEIC",
                                        comment: "File name used for App Store screenshot"),
                totalBytes: 1067226
            ),
            FileTransferItemInfo(
                path: URL(string: "file://IMG_1234.mov")!,
                name: NSLocalizedString("Birthday.mov",
                                        comment: "File name used for App Store screenshot"),
                totalBytes: 4611303
            ),
        ]
        macBook.numFilesSuccessfullySent = 1
        macBook.totalNumOfFilesToSend = 4
        macBook.filesFailedToSend = [
            // something about open source
            FailedFileTransferItemInfo(
                path: URL(string: "file://schematics.pdf")!,
                name: NSLocalizedString("schematics.pdf",
                                        comment: "A file name used in App Store screenshot for one that failed to be sent to the MacBook. Schematics are essential for performing repairs that involve fixing hardware problems without replacing the entire motherboard."),
                error: CocoaError(.fileReadNoPermission),
                countOtherFailedFilesInTheSameTransfer: 2
            ),
        ]
        
        macBook.currentFilesReceiving = makeCurrentFilesDictionary(for: [
            FileTransferItemInfo(
                path: URL(string: "file://WWDC/SwiftStudentChallenge.swiftpm")!,
                name: "KDE Connect.swiftpm",
                totalBytes: 68669,
                totalBytesCompleted: 42135
            ),
        ])
        macBook.numFilesReceived = 3
        macBook.totalNumOfFilesToReceive = 5
        
        // MARK: Desktop e.g. Plasma
        // Only the files sending will appear in App Store screenshots
        
        desktop.currentFilesSending = makeCurrentFilesDictionary(for: [
            FileTransferItemInfo(
                path: URL(string: "file://are-ya-winning-son.gif")!,
                name: NSLocalizedString("meme.gif",
                                        comment: "File name used for App Store screenshot. Here meme is a funny GIF, such as nyan cat."),
                totalBytes: 873432,
                totalBytesCompleted: 123456
            ),
        ])
        desktop.filesToSend = [
            FileTransferItemInfo(
                path: URL(string: "file://demo.mp4")!,
                name: NSLocalizedString("demo.mp4",
                                        comment: "File name used for App Store screenshot. Here demo means demonstration, or a presentation to showcase something."),
                totalBytes: 1144639211
            ),
        ]
        desktop.numFilesSuccessfullySent = 0
        desktop.totalNumOfFilesToSend = 2
        
        desktop.currentFilesReceiving = makeCurrentFilesDictionary(for: [
            FileTransferItemInfo(
                path: URL(string: "file://logo.png")!,
                name: "logo.png",
                totalBytes: 152167,
                totalBytesCompleted: 34610
            ),
        ])
        desktop.numFilesReceived = 0
        desktop.totalNumOfFilesToReceive = 1
        desktop.filesFailedToReceive = [
            FailedFileTransferItemInfo(
                path: URL(string: "file://sideload.ipa")!,
                name: "KDE Connect.ipa",
                error: CocoaError(.executableNotLoadable),
                countOtherFailedFilesInTheSameTransfer: 0
            ),
        ]
    }
    
    static func getSharePlugin(for deviceID: DeviceID) -> Share {
        backgroundService.devices[deviceID.rawValue]!.plugins[.share] as! Share
    }
    
    static func makeCurrentFilesDictionary(
        for items: [FileTransferItemInfo]
    ) -> OrderedDictionary<URL, FileTransferItemInfo> {
        OrderedDictionary(uniqueKeysWithValues: items.map { ($0.path, $0) })
    }
}
#endif
