/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  Presenter.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-09-13.
//

import Foundation

@objc class Presenter : NSObject, Plugin {
    @objc weak var controlDevice: Device!
    
    @objc init (controlDevice: Device) {
        self.controlDevice = controlDevice
    }
    
    @objc func onDevicePackageReceived(np: NetworkPackage) -> Bool {
        if (np.type == .presenter) {
            print("Presenter received a package, can't do anything about it, ignoring")
            return true
        }
        return false
    }
    
    @objc func sendNext() {
        let np: NetworkPackage = NetworkPackage(type: .mousePadRequest)
        np.setInteger(KeyEvent.KEYCODE_PAGE_DOWN.rawValue, forKey: "specialKey")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_MOUSEPAD))
    }
    
    @objc func sendPrevious() {
        let np: NetworkPackage = NetworkPackage(type: .mousePadRequest)
        np.setInteger(KeyEvent.KEYCODE_PAGE_UP.rawValue, forKey: "specialKey")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_MOUSEPAD))
    }
    
    @objc func sendFullscreen() {
        let np: NetworkPackage = NetworkPackage(type: .mousePadRequest)
        np.setInteger(KeyEvent.KEYCODE_F5.rawValue, forKey: "specialKey")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_MOUSEPAD))
    }
    
    @objc func sendEsc() {
        let np: NetworkPackage = NetworkPackage(type: .mousePadRequest)
        np.setInteger(KeyEvent.KEYCODE_ESCAPE.rawValue, forKey: "specialKey")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_MOUSEPAD))
    }
    
    @objc func sendPointerPosition(dx: Float, dy: Float) {
        let np: NetworkPackage = NetworkPackage(type: .presenter)
        np.setFloat(dx, forKey: "dx")
        np.setFloat(dy, forKey: "dy")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_NORMAL))
    }
    
    @objc func sendStopPointer() {
        let np: NetworkPackage = NetworkPackage(type: .presenter)
        np.setBool(true, forKey: "stop")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_NORMAL))
    }
}
