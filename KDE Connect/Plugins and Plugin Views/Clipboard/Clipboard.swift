/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  Clipboard.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-09-05.
//

#if !os(macOS)
import UIKit
#else
import AppKit
#endif

@objc class Clipboard: NSObject, Plugin {
    static var lastLocalClipboardUpdateTimestamp: Int = Int(Date().millisecondsSince1970)
    // iOS doesn't notify us when other apps change the pasteboard, but changeCount (which can be
    // read without a paste prompt) tells us if it changed since we last looked
    private static var lastKnownChangeCount: Int?
    @objc weak var controlDevice: Device!
    private let logger = Logger()
    
    @objc init(controlDevice: Device) {
        self.controlDevice = controlDevice
        super.init()
        Self.updateTimestampIfChangedByOthers()
    }
    
    @objc func onDevicePacketReceived(np: NetworkPacket) {
        if (np.type == .clipboard || np.type == .clipboardConnect) {
            if (np.object(forKey: "content") != nil) {
                if (np.type == .clipboard) {
                    Self.setLocalClipboard(np.object(forKey: "content") as? String)
                    logger.debug("Local clipboard synced with remote packet, timestamp updated")
                } else if (np.type == .clipboardConnect) {
                    Self.updateTimestampIfChangedByOthers()
                    let packetTimeStamp: Int = np.integer(forKey: "timestamp")
                    if (packetTimeStamp == 0 || packetTimeStamp < Self.lastLocalClipboardUpdateTimestamp) {
                        logger.info("Invalid timestamp from \(np.type.rawValue, privacy: .public), doing nothing")
                    } else {
                        Self.setLocalClipboard(np.object(forKey: "content") as? String)
                        logger.debug("Local clipboard synced with remote packet, timestamp updated")
                    }
                }
            } else {
                logger.debug("Received nil for the content of the remote device's \(np.type.rawValue, privacy: .public), doing nothing")
            }
        }
    }
    
    private static var pasteboardChangeCount: Int {
#if !os(macOS)
        UIPasteboard.general.changeCount
#else
        NSPasteboard.general.changeCount
#endif
    }
    
    // If another app changed the pasteboard since we last looked, we don't know when it happened,
    // so assume it was now: a local copy is never replaced by an older clipboard.connect packet
    private static func updateTimestampIfChangedByOthers() {
        let changeCount = pasteboardChangeCount
        if let lastKnownChangeCount, lastKnownChangeCount != changeCount {
            lastLocalClipboardUpdateTimestamp = Int(Date().millisecondsSince1970)
        }
        lastKnownChangeCount = changeCount
    }
    
    private static func setLocalClipboard(_ content: String?) {
#if !os(macOS)
        UIPasteboard.general.string = content
#else
        NSPasteboard.general.setString(content ?? "", forType: .string)
#endif
        lastLocalClipboardUpdateTimestamp = Int(Date().millisecondsSince1970)
        lastKnownChangeCount = pasteboardChangeCount
    }
    
    func sendClipboardContentOut() {
#if !os(macOS)
        // On iOS 16+ this shows an "Allow Paste" prompt (unless "Paste from Other Apps" is set to
        // "Allow" in the app settings), and returns nil if the user denies it
        let clipboardContent = UIPasteboard.general.string
#else
        let clipboardContent = NSPasteboard.general.string(forType: .string)
#endif
        if let clipboardContent {
            let np = NetworkPacket(type: .clipboard)
            np.setObject(clipboardContent, forKey: "content")
            controlDevice.send(np, tag: Int(PACKET_TAG_CLIPBOARD))
        } else {
#if !os(macOS)
            // hasStrings doesn't need authorization
            if UIPasteboard.general.hasStrings {
                logger.info("Reading the clipboard was not authorized")
                return
            }
#endif
            logger.info("Attempt to grab and update local clipboard content returned nil")
        }
    }
}
