/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  FindMyPhone.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-08-13.
//

import Foundation

@objc class FindMyPhone : NSObject, Plugin {
    @objc let controlDevice: Device
    
    @objc init (controlDevice: Device) {
        self.controlDevice = controlDevice
    }
    
    @objc func onDevicePackageReceived(np: NetworkPackage) -> Bool {
        if (np.type == .findMyPhoneRequest) {
            connectedDevicesViewModel.showFindMyPhoneAlert()
            return true
        }
        return false
    }
    
    @objc func sendFindMyPhoneRequest() -> Void {
        let np: NetworkPackage = NetworkPackage(type: .findMyPhoneRequest)
        controlDevice.send(np, tag: 0)
    }
}
