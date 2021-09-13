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
        if (np._Type == PACKAGE_TYPE_PING) {
            connectedDevicesViewModel.showPingAlert()
            return true
        }
        return false
    }
    
    @objc func sendPing() -> Void {
        let np: NetworkPackage = NetworkPackage(type: PACKAGE_TYPE_PING)
        controlDevice.send(np, tag: Int(PACKAGE_TAG_PING))
    }
}
