//
//  Battery.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-08-13.
//

import UIKit

class Battery : Plugin {
    
    func onDevicePackageReceived(np: NetworkPackage) -> Bool {
        if (np._Type == PACKAGE_TYPE_BATTERY_REQUEST) {
            UIDevice.current.isBatteryMonitoringEnabled = true
            let batteryLevel: Int = Int(UIDevice.current.batteryLevel)
            let batteryStatus = UIDevice.current.batteryState
            UIDevice.current.isBatteryMonitoringEnabled = false
            let np: NetworkPackage = NetworkPackage(type: PACKAGE_TYPE_BATTERY)
            if (batteryStatus != .unknown) {
                let batteryThresholdEvent: Int = (batteryLevel < 10) ? 1 : 0
                np.setInteger(batteryLevel, forKey: "currentCharge")
                np.setBool((batteryStatus == .charging), forKey: "isCharging")
                np.setInteger(batteryThresholdEvent, forKey: "thresholdEvent")
            } else {
                np.setInteger(0, forKey: "currentCharge")
                np.setBool(false, forKey: "isCharging")
                np.setInteger(0, forKey: "thresholdEvent")
            }
            // TODO: Currently all plugins are device agnostic, since we don't know which
            // device actually requested the battery status, we'll just send it to all connected
            // devices for now
            for deviceId in connectedDevicesViewModel.connectedDevices.keys {
                (backgroundService._devices[deviceId] as! Device).send(np, tag: Int(PACKAGE_TAG_BATTERY))
            }
            return true
        }
        return false
    }
}
