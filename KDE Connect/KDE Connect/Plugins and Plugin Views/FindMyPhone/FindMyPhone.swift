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

extension Notification.Name {
    static let didReceiveFindMyPhoneRequestNotification = Notification.Name("didReceiveFindMyPhoneRequestNotification")
}

@objc class FindMyPhone : NSObject, Plugin {
    @objc weak var controlDevice: Device!
    
    @objc init (controlDevice: Device) {
        self.controlDevice = controlDevice
    }
    
    @objc func onDevicePackageReceived(np: NetworkPackage) -> Bool {
        if (np.type == .findMyPhoneRequest) {
            NotificationCenter.default.post(name: .didReceiveFindMyPhoneRequestNotification, object: nil)
            return true
        }
        return false
    }
    
    @objc func sendFindMyPhoneRequest() {
        let np: NetworkPackage = NetworkPackage(type: .findMyPhoneRequest)
        controlDevice.send(np, tag: 0)
    }
}
