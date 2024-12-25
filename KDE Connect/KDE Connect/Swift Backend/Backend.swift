/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  Backend.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-08-04.
//

import Foundation
import CoreMotion

// A place to house miscellaneous functions and variables for global usage by the rest of the app

// ViewModel object for devices-related functionalities
// TODO: Should this be kept global or local to DevicesView()? Reference might break if this is
// TODO: if global, make singelton
// global but making it local to DevicesView() would likely make it harder to access values in it
// We'll finish developing everything else and see if anything other than DevicesView() needs it.
// I think we probably do since the Unpair function is now in the details view instead of the
// DevicesView()
let connectedDevicesViewModel: ConnectedDevicesViewModel = ConnectedDevicesViewModel()

// Global ObservableObject to be Observed by needed structs for app-wide information
@available(*, deprecated, renamed: "KdeConnectSettings.shared")
let kdeConnectSettings: KdeConnectSettings = .shared

// Background Service provider, bridged from Obj-C codebase
let backgroundService: BackgroundService = {
#if DEBUG
    let setupScreenshotDevices = ProcessInfo.processInfo.arguments.contains("setupScreenshotDevices")
#else
    let setupScreenshotDevices = false
#endif
    return BackgroundService(
        // disconnect background service from connected devices view model if taking screenshots
        // so the UI testing instances will only access to fake devices
        connectedDeviceViewModel: setupScreenshotDevices ? nil : connectedDevicesViewModel
    )
}()

#if !os(macOS)
// Device motion manager
let motionManager: CMMotionManager = CMMotionManager()
#endif

// Given the deviceId, saves/overwrites the device object from _device into _settings by encoding it and then into UserDefaults
func saveDeviceToUserDefaults(deviceId: String) {
    let deviceData: Data?
    do {
        deviceData = try NSKeyedArchiver.archivedData(withRootObject: backgroundService._devices[deviceId]!, requiringSecureCoding: true)
    } catch {
        Logger(category: "Device").fault("\(error.localizedDescription, privacy: .public)")
        return
    }
    backgroundService.settings[backgroundService.devices[deviceId]!._deviceInfo.id] = deviceData
    UserDefaults.standard.setValue(backgroundService.settings, forKey: "savedDevices")
}
