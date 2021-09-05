//
//  Battery.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-08-13.
//

import UIKit

// TODO: We might be able to do something with the background activities plugin where it sends out its battery status every once in a while??? But maybe iOS will not unfreeze the entire app for us??? I really don't know...background activity is something that we'll have to figure out later on
@objc class Battery : NSObject, Plugin {
    @objc let controlDevice: Device
    
    @objc init (controlDevice: Device) {
        self.controlDevice = controlDevice
        super.init()
        self.startBatteryMonitoring()
        self.sendBatteryStatusOut()
    }
    
    @objc func startBatteryMonitoring() -> Void {
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        // Tip: to add an observer with a function/selector in another class that is not self,
        // simply replace both self in the call with the instance where the function is located
        NotificationCenter.default.addObserver(self, selector: #selector(self.batteryStateDidChange(notification:)), name: UIDevice.batteryStateDidChangeNotification, object: UIDevice.current)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.batteryLevelDidChange(notification:)), name: UIDevice.batteryLevelDidChangeNotification, object: UIDevice.current)
    }
    
    @objc func onDevicePackageReceived(np: NetworkPackage) -> Bool {
        if (np._Type == PACKAGE_TYPE_BATTERY_REQUEST) {
            print("Battery plugin recevied a force update request")
            sendBatteryStatusOut()
            return true
        }
        return false
    }
    
    @objc func sendBatteryStatusOut() -> Void {
        let batteryLevel: Int = Int(UIDevice.current.batteryLevel * 100)
        let batteryStatus = UIDevice.current.batteryState
        let np: NetworkPackage = NetworkPackage(type: PACKAGE_TYPE_BATTERY)
        if (batteryStatus != .unknown) {
            let batteryThresholdEvent: Int = (batteryLevel < 10) ? 1 : 0
            np.setInteger(batteryLevel, forKey: "currentCharge")
            np.setBool((batteryStatus == .charging), forKey: "isCharging")
            np.setInteger(batteryThresholdEvent, forKey: "thresholdEvent")
            print("Battery status accessed successfully, sending out:")
            print("BatteryLevel=\(batteryLevel)")
            print("BatteryisCharging=\(batteryStatus == .charging)")
        } else {
            np.setInteger(0, forKey: "currentCharge")
            np.setBool(false, forKey: "isCharging")
            np.setInteger(0, forKey: "thresholdEvent")
            print("Battery status reported as unknown, reporting 0 for all values")
        }
        controlDevice.send(np, tag: Int(PACKAGE_TAG_BATTERY))
    }
    
    // Global functions for setting up and responding to the device's own events when battery
    // status changes
    
    // When the state of the battery changes: plugged, unplugged, full charge, unknown
    @objc func batteryStateDidChange(notification: Notification) {
        sendBatteryStatusOut()
    }
    
    // When the percentage level of the battery changes
    @objc func batteryLevelDidChange(notification: Notification) {
        sendBatteryStatusOut()
    }
}

// Global functions for Battery handling
func startBatteryMonitoringAllDevices() {
    for case let device as Device in (backgroundService._devices.allValues) {
        if (device.isPaired() && device._plugins.allKeys.contains(where: {$0 as! String == PACKAGE_TYPE_BATTERY_REQUEST})) {
            (device._plugins[PACKAGE_TYPE_BATTERY_REQUEST] as! Battery).startBatteryMonitoring()
        }
    }
}

func broadcastBatteryStatusAllDevices() {
    for case let device as Device in (backgroundService._devices.allValues) {
        if (device.isPaired() && device._plugins.allKeys.contains(where: {$0 as! String == PACKAGE_TYPE_BATTERY_REQUEST})) {
            (device._plugins[PACKAGE_TYPE_BATTERY_REQUEST] as! Battery).sendBatteryStatusOut()
        }
    }
}
