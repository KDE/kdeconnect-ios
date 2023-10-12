/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  RemoteInput.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-09-06.
//

@objc class RemoteInput: NSObject, Plugin {
    enum SpecialKey: Int {
        case invalid = 0,
        backspace = 1,
        tab = 2, // also can't type this
        `return` = 12
        // there are many other keys, but we can't type them directly on iOS so don't bother (for now)
    }
    @objc weak var controlDevice: Device!
    private let logger = Logger()
    
    @objc init (controlDevice: Device) {
        self.controlDevice = controlDevice
    }
    
    @objc func onDevicePackageReceived(np: NetworkPackage) {
        if (np.type == .mousePadRequest) {
            logger.info("Received mousepad command, doing nothing")
        }
    }
    
    @objc func sendMouseDelta(dx: Float, dy: Float) {
        let np: NetworkPackage = NetworkPackage(type: .mousePadRequest)
        np.setFloat(dx, forKey: "dx")
        np.setFloat(dy, forKey: "dy")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_MOUSEPAD))
    }
    
    @objc func sendSingleClick() {
        let np: NetworkPackage = NetworkPackage(type: .mousePadRequest)
        np.setBool(true, forKey: "singleclick")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_MOUSEPAD))
    }
    
    @objc func sendDoubleClick() {
        let np: NetworkPackage = NetworkPackage(type: .mousePadRequest)
        np.setBool(true, forKey: "doubleclick")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_MOUSEPAD))
    }
    
    @objc func sendKeyPress(_ keys: String) {
        let np = NetworkPackage(type: .mousePadRequest)
        np.setObject(keys, forKey: "key")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_MOUSEPAD))
    }
    
    @objc func sendSpecialKeyPress(_ key: Int) {
        let np = NetworkPackage(type: .mousePadRequest)
        np.setInteger(key, forKey: "specialKey")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_MOUSEPAD))
    }
    
    @objc func sendMiddleClick() {
        let np: NetworkPackage = NetworkPackage(type: .mousePadRequest)
        np.setBool(true, forKey: "middleclick")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_MOUSEPAD))
    }
    
    @objc func sendRightClick() {
        let np: NetworkPackage = NetworkPackage(type: .mousePadRequest)
        np.setBool(true, forKey: "rightclick")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_MOUSEPAD))
    }
    
    @objc func sendSingleHold() {
        let np: NetworkPackage = NetworkPackage(type: .mousePadRequest)
        np.setBool(true, forKey: "singlehold")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_MOUSEPAD))
    }
    
    @objc func sendScroll(dx: Float, dy: Float) {
        let np: NetworkPackage = NetworkPackage(type: .mousePadRequest)
        np.setBool(true, forKey: "scroll")
        np.setFloat(dx, forKey: "dx")
        np.setFloat(dy, forKey: "dy")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_MOUSEPAD))
    }
}
