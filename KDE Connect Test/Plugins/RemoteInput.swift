//
//  RemoteInput.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-09-06.
//

import Foundation

@objc class RemoteInput : NSObject, Plugin {
    @objc let controlDevice: Device
    
    @objc init (controlDevice: Device) {
        self.controlDevice = controlDevice
    }
    
    @objc func onDevicePackageReceived(np: NetworkPackage) -> Bool {
        if (np._Type == PACKAGE_TYPE_MOUSEPAD) {
            print("Received mousepad command, doing nothing")
            return true
        }
        return false
    }
    
    @objc func sendMouseDelta(Dx: Double, Dy: Double) -> Void {
        let np: NetworkPackage = NetworkPackage(type: PACKAGE_TYPE_MOUSEPAD)
        np.setDouble(Dx, forKey: "dx")
        np.setDouble(Dy, forKey: "dy")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_MOUSEPAD))
    }
    
    @objc func sendSingleClick() -> Void {
        let np: NetworkPackage = NetworkPackage(type: PACKAGE_TYPE_MOUSEPAD)
        np.setBool(true, forKey: "singleclick")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_MOUSEPAD))
    }
    
    @objc func sendDoubleClick() -> Void {
        let np: NetworkPackage = NetworkPackage(type: PACKAGE_TYPE_MOUSEPAD)
        np.setBool(true, forKey: "doubleclick")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_MOUSEPAD))
    }
    
    @objc func sendMiddleClick() -> Void {
        let np: NetworkPackage = NetworkPackage(type: PACKAGE_TYPE_MOUSEPAD)
        np.setBool(true, forKey: "middleclick")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_MOUSEPAD))
    }
    
    @objc func sendRightClick() -> Void {
        let np: NetworkPackage = NetworkPackage(type: PACKAGE_TYPE_MOUSEPAD)
        np.setBool(true, forKey: "rightclick")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_MOUSEPAD))
    }
    
    @objc func sendSingleHold() -> Void {
        let np: NetworkPackage = NetworkPackage(type: PACKAGE_TYPE_MOUSEPAD)
        np.setBool(true, forKey: "singlehold")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_MOUSEPAD))
    }
}
