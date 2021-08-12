//
//  Ping.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-08-11.
//

import Foundation

class Ping : Plugin {
    
    func onDevicePackageReceived(np: NetworkPackage) -> Bool {
        if (np._Type == PACKAGE_TYPE_PING) {
            haptics.impactOccurred(intensity: 1.0)
            return true
        }
        return false
    }
    
    func sendPing(deviceId: String) -> Void {
        let np: NetworkPackage = NetworkPackage(type: PACKAGE_TYPE_PING)
        let device: Device = backgroundService._devices[deviceId] as! Device
        device.send(np, tag: Int(PACKAGE_TAG_PING))
    }
}
