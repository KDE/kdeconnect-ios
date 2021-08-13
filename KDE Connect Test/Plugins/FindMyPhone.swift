//
//  FindMyPhone.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-08-13.
//

import Foundation

class FindMyPhone : Plugin {
    
    func onDevicePackageReceived(np: NetworkPackage) -> Bool {
        if (np._Type == PACKAGE_TYPE_FINDMYPHONE_REQUEST) {
            connectedDevicesViewModel.showFindMyPhoneAlert()
            return true
        }
        return false
    }
    
    func sendFindMyPhoneRequest(deviceId: String) -> Void {
        let np: NetworkPackage = NetworkPackage(type: PACKAGE_TYPE_FINDMYPHONE_REQUEST)
        let device: Device = backgroundService._devices[deviceId] as! Device
        device.send(np, tag: 0)
    }
}
