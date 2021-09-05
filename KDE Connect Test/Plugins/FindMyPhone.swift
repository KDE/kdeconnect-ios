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
        if (np._Type == PACKAGE_TYPE_FINDMYPHONE_REQUEST) {
            connectedDevicesViewModel.showFindMyPhoneAlert()
            return true
        }
        return false
    }
    
    @objc func sendFindMyPhoneRequest() -> Void {
        let np: NetworkPackage = NetworkPackage(type: PACKAGE_TYPE_FINDMYPHONE_REQUEST)
        controlDevice.send(np, tag: 0)
    }
}
