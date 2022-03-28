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

@objc class RemoteInput : NSObject, Plugin {
    @objc weak var controlDevice: Device!
    
    @objc init (controlDevice: Device) {
        self.controlDevice = controlDevice
    }
    
    @objc func onDevicePackageReceived(np: NetworkPackage) -> Bool {
        if (np.type == .mousePadRequest) {
            print("Received mousepad command, doing nothing")
            return true
        }
        return false
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
    
    @objc func sendScroll(Dx: Float, Dy: Float) {
        let np: NetworkPackage = NetworkPackage(type: .mousePadRequest)
        np.setBool(true, forKey: "scroll")
        np.setFloat(Dx, forKey: "dx")
        np.setFloat(Dy, forKey: "dy")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_MOUSEPAD))
    }
}
