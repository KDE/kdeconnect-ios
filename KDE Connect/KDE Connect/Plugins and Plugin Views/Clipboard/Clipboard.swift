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

import UIKit

@objc class Clipboard: NSObject, Plugin {
    static var lastLocalClipboardUpdateTimestamp: Int = 0
    @objc weak var controlDevice: Device!
    private let logger = Logger()
    
    @objc init(controlDevice: Device) {
        self.controlDevice = controlDevice
    }
    
    @objc func onDevicePackageReceived(np: NetworkPackage) -> Bool {
        if (np.type == .clipboard || np.type == .clipboardConnect) {
            if (np.object(forKey: "content") != nil) {
                if (np.type == .clipboard) {
                    UIPasteboard.general.string = np.object(forKey: "content") as? String
                    Self.lastLocalClipboardUpdateTimestamp = Int(Date().millisecondsSince1970)
                    logger.debug("Local clipboard synced with remote packet, timestamp updated")
                } else if (np.type == .clipboardConnect) {
                    let packetTimeStamp: Int = np.integer(forKey: "timestamp")
                    if (packetTimeStamp == 0 || packetTimeStamp < Self.lastLocalClipboardUpdateTimestamp) {
                        logger.info("Invalid timestamp from \(np.type.rawValue, privacy: .public), doing nothing")
                        return false
                    } else {
                        UIPasteboard.general.string = np.object(forKey: "content") as? String
                        Self.lastLocalClipboardUpdateTimestamp = Int(Date().millisecondsSince1970)
                        logger.debug("Local clipboard synced with remote packet, timestamp updated")
                    }
                }
            } else {
                logger.debug("Received nil for the content of the remote device's \(np.type.rawValue, privacy: .public), doing nothing")
            }
            return true
        }
        return false
    }
    
    // FIXME: unused function
    func connectClipboardContent() {
        if let clipboardContent = UIPasteboard.general.string {
            let np = NetworkPackage(type: .clipboardConnect)
            np.setObject(clipboardContent, forKey: "content")
            np.setInteger(Self.lastLocalClipboardUpdateTimestamp, forKey: "timestamp")
            controlDevice.send(np, tag: Int(PACKAGE_TAG_CLIPBOARD))
        } else {
            logger.info("Attempt to connect local clipboard content with remote device returned nil")
        }
    }
    
    func sendClipboardContentOut() {
        if let clipboardContent = UIPasteboard.general.string {
            let np = NetworkPackage(type: .clipboard)
            np.setObject(clipboardContent, forKey: "content")
            controlDevice.send(np, tag: Int(PACKAGE_TAG_CLIPBOARD))
        } else {
            logger.info("Attempt to grab and update local clipboard content returned nil")
        }
    }
}
