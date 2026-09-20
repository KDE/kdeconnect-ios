/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  Ping.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-08-11.
//

import Foundation

extension Notification.Name {
    static let didReceivePingNotification = Notification.Name("didReceivePingNotification")
}

@objc class Ping: NSObject, Plugin {
    @objc weak var controlDevice: Device!
    
    @objc init (controlDevice: Device) {
        self.controlDevice = controlDevice
    }
    
    @objc func onDevicePacketReceived(np: NetworkPacket) {
        if (np.type == .ping) {
            NotificationCenter.default.post(name: .didReceivePingNotification, object: nil)
        }
    }
    
    @objc func sendPing() {
        let np: NetworkPacket = NetworkPacket(type: .ping)
        controlDevice.send(np, tag: Int(PACKET_TAG_PING))
    }
}
