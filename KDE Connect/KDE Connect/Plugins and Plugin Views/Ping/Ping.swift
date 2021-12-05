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

@objc class Ping : NSObject, Plugin {
    @objc let controlDevice: Device
    
    @objc init (controlDevice: Device) {
        self.controlDevice = controlDevice
    }
    
    @objc func onDevicePackageReceived(np: NetworkPackage) -> Bool {
        if (np.type == .ping) {
            connectedDevicesViewModel.showPingAlert()
            return true
        }
        return false
    }
    
    @objc func sendPing() -> Void {
        let np: NetworkPackage = NetworkPackage(type: .ping)
        controlDevice.send(np, tag: Int(PACKAGE_TAG_PING))
    }
}
