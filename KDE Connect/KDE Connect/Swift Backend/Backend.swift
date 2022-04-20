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
import UIKit
import CoreMotion
import SwiftUI
// A place to house miscellaneous functions and variables for global usage by the rest of the app

// Certificate Service provider, to be usef for all certificate and Keychain operations
let certificateService: CertificateService = CertificateService()

// ViewModel object for devices-related functionalities
// TODO: Should this be kept global or local to DevicesView()? Reference might break if this is
// TODO: if global, make singelton
// global but making it local to DevicesView() would likely make it harder to access values in it
// We'll finish developing everything else and see if anything other than DevicesView() needs it.
// I think we probably do since the Unpair function is now in the details view instead of the
// DevicesView()
let connectedDevicesViewModel: ConnectedDevicesViewModel = ConnectedDevicesViewModel()

// Global ObservableObject to be Observed by needed structs for app-wide information
let selfDeviceData: SelfDeviceData = SelfDeviceData()

// Background Service provider, bridged from Obj-C codebase
let backgroundService: BackgroundService = BackgroundService(connectedDeviceViewModel: connectedDevicesViewModel, certificateService: certificateService)

// Haptics provider, for a list of the enum values see
// https://developer.apple.com/documentation/uikit/uiimpactfeedbackgenerator/feedbackstyle
extension UIImpactFeedbackGenerator.FeedbackStyle : CaseIterable {
    public var text: Text {
        switch self {
        case .light: return Text("Light", comment: "Light haptic feedback level")
        case .medium: return Text("Medium", comment: "Medium haptic feedback level")
        case .heavy: return Text("Heavy", comment: "Hard haptic feedback level")
        case .soft: return Text("Soft", comment: "Soft haptic feedback level")
        case .rigid: return Text("Rigid", comment: "Rigid haptic feedback level")
        @unknown default: return Text("Other", comment: "Unknown haptic feedback level")
        }
    }
    
    public static var allCases: [UIImpactFeedbackGenerator.FeedbackStyle] {
        return [.light, .medium, .heavy, .soft, .rigid]
    }
}

//UIImpactFeedbackGenerator.FeedbackStyle.init(rawValue: Int)

let notificationHapticsGenerator: UINotificationFeedbackGenerator = UINotificationFeedbackGenerator()

// Device motion manager
let motionManager: CMMotionManager = CMMotionManager()

// Date extension to return the UNIX epoche in miliseconds, since KDE Connect uses miliseconds
// UNIX Epoche for all timestamp fields:
// https://stackoverflow.com/questions/40134323/date-to-milliseconds-and-back-to-date-in-swift
extension Date {
    var millisecondsSince1970: Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }

    init(milliseconds: Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}

extension LocalizedStringKey.StringInterpolation {
    mutating func appendInterpolation(percent: Int) {
        if #available(iOS 15, *) {
            appendInterpolation(Double(percent) / 100, format: .percent)
        } else {
            appendInterpolation(Double(percent) / 100 as NSNumber, formatter: NumberFormatter.percentage)
        }
    }
}

fileprivate extension NumberFormatter {
    static let percentage: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        return formatter
    }()
}

public extension DeviceType {
    var sfSymbolName: String {
        switch (self) {
            case .unknown: return "questionmark.square.dashed"
            case .desktop: return "desktopcomputer"
            case .laptop: return "laptopcomputer"
            case .phone: return "apps.iphone"
            case .tablet: return "apps.ipad.landscape"
            case .tv: return "tv"
            @unknown default: return "questionmark.square.dashed"
        }
    }

    static var current: DeviceType {
        var macDeviceType: DeviceType {
            "hw.model".withCString { hwModelCStr in
                var size = 0
                if sysctlbyname(hwModelCStr, nil, &size, nil, 0) != 0 {
                    print("Failed to get size of hw.model (\(String(cString: strerror(errno))))")
                    return .unknown
                }
                precondition(size > 0)
                var resultCStr = [CChar](repeating: 0, count: size)
                if sysctlbyname(hwModelCStr, &resultCStr, &size, nil, 0) != 0 {
                    print("Failed to get hw.model (\(String(cString: strerror(errno))))")
                    return .unknown
                }
                // https://everymac.com/systems/by_capability/mac-specs-by-machine-model-machine-id.html
                switch String(cString: resultCStr) {
                case let model where model.starts(with: "MacBook"):
                    return .laptop
                case let model where model.contains("Mac"):
                    return .desktop
                case let model:
                    print("Unexpected hw.model (\(model)")
                    return .unknown
                }
            }
        }
        switch UIDevice.current.userInterfaceIdiom {
        case .unspecified:
            return .unknown
        case .phone:
            return .phone
        case .pad:
            let processInfo = ProcessInfo.processInfo
            if processInfo.isMacCatalystApp || processInfo.isiOSAppOnMac {
                return macDeviceType
            }
            return .tablet
        case .tv:
            return .tv
        case .carPlay:
            return .unknown
        case .mac:
            return macDeviceType
        @unknown default:
            return .unknown
        }
    }
}

extension Device {
    @objc
    @available(swift, obsoleted: 1.0, message: "Use 'DeviceType.current' instead")
    static var currentDeviceType: DeviceType {
        return DeviceType.current
    }
}

// Given the deviceId, saves/overwrites the device object from _device into _settings by encoding it and then into UserDefaults
func saveDeviceToUserDefaults(deviceId: String) {
    let deviceData: Data?
    do {
        deviceData = try NSKeyedArchiver.archivedData(withRootObject: backgroundService._devices[deviceId]!, requiringSecureCoding: true)
    } catch {
        print(error.localizedDescription)
        return
    }
    backgroundService.settings[backgroundService.devices[deviceId]!._id] = deviceData
    UserDefaults.standard.setValue(backgroundService.settings, forKey: "savedDevices")
}

// Uniform Key inputs

// KeyEvent is NOT a part of any iOS API, it's a custom enum
// KeyEvent is indeed part of AppKit for macOS (but not any other OS), and SwiftUI for iOS does have
// limited support, but at this time ONLY for external keyboards.
// All of these matches the Android SpecialKeysMap as defined in KeyListenerView.java
// Even if a lot of them are not used in iOS
enum KeyEvent: Int {
    case KEYCODE_DEL            = 1
    case KEYCODE_TAB            = 2
    // 3 is not used, ENTER share the same value as NUMPAD_ENTER, 12
    case KEYCODE_DPAD_LEFT      = 4
    case KEYCODE_DPAD_UP        = 5
    case KEYCODE_DPAD_RIGHT     = 6
    case KEYCODE_DPAD_DOWN      = 7
    case KEYCODE_PAGE_UP        = 8
    case KEYCODE_PAGE_DOWN      = 9
    case KEYCODE_MOVE_HOME      = 10
    case KEYCODE_MOVE_END       = 11
    //case KEYCODE_NUMPAD_ENTER   = 12
    case KEYCODE_ENTER          = 12
    case KEYCODE_FORWARD_DEL    = 13
    case KEYCODE_ESCAPE         = 14
    case KEYCODE_SYSRQ          = 15
    case KEYCODE_SCROLL_LOCK    = 16
    // 17 is not used
    // 18 is not used
    // 19 is not used
    // 20 is not used
    case KEYCODE_F1             = 21
    case KEYCODE_F2             = 22
    case KEYCODE_F3             = 23
    case KEYCODE_F4             = 24
    case KEYCODE_F5             = 25
    case KEYCODE_F6             = 26
    case KEYCODE_F7             = 27
    case KEYCODE_F8             = 28
    case KEYCODE_F9             = 29
    case KEYCODE_F10            = 30
    case KEYCODE_F11            = 31
    case KEYCODE_F12            = 32
}

// MARK: - Migration

// This section contains code that keeps the project compiling, but
#warning("TODO: needs migration")

// Please always use the non-deprecated spelling if possible, and
// follow the compiler warnings when ready to migrate existing code
// after uncommenting lines containing `@available`

extension BackgroundService {
    // @available(*, deprecated, renamed: "devices")
    var _devices: [String: Device] {
        return devices
    }
}

extension Device {
    // @available(*, deprecated, renamed: "plugins")
    var _plugins: [NetworkPackage.`Type`: Plugin] {
        plugins
    }

    // @available(*, deprecated, renamed: "pluginsEnableStatus")
    var _pluginsEnableStatus: [NetworkPackage.`Type`: NSNumber] {
        get {
            pluginsEnableStatus
        }
        set {
            pluginsEnableStatus = newValue
        }
    }
}
