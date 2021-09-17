//
//  Backend.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-08-04.
//

import Foundation
import UIKit
import AVFoundation
import CoreMotion
// A place to house miscellaneous functions and variables for global usage by the rest of the app

// Background Service provider, bridged from Obj-C codebase
let backgroundService: BackgroundService = BackgroundService()

// ViewModel object for devices-related functionalities
// TODO: Should this be kept global or local to DevicesView()? Reference might break if this is
// global but making it local to DevicesView() would likely make it harder to access values in it
// We'll finish developing everything else and see if anything other than DevicesView() needs it.
// I think we probably do since the Unpair function is now in the details view instead of the
// DevicesView()
let connectedDevicesViewModel: ConnectedDevicesViewModel = ConnectedDevicesViewModel()

// Global ObservableObject to be Observed by needed structs for app-wide information
let selfDeviceData: SelfDeviceData = SelfDeviceData()

// Haptics provider
let hapticGenerators: [UIImpactFeedbackGenerator] =
    [
        UIImpactFeedbackGenerator(style: .light),
        UIImpactFeedbackGenerator(style: .medium),
        UIImpactFeedbackGenerator(style: .heavy),
        UIImpactFeedbackGenerator(style: .soft),
        UIImpactFeedbackGenerator(style: .rigid)
    ]

let notificationHapticsGenerator: UINotificationFeedbackGenerator = UINotificationFeedbackGenerator()

// Device motion manager
let motionManager: CMMotionManager = CMMotionManager()

// System sounds definitions, for a list of all IDs, see
// https://github.com/TUNER88/iOSSystemSoundsLibrary
let soundMailReceived: SystemSoundID = 1000
let soundMailSent: SystemSoundID = 1001
let soundSMSReceived: SystemSoundID = 1003
let soundCalendarAlert: SystemSoundID = 1005
let soundAudioToneBusy: SystemSoundID = 1070

// Date extension to return the UNIX epoche in miliseconds, since KDE Connect uses miliseconds
// UNIX Epoche for all timestamp fields:
// https://stackoverflow.com/questions/40134323/date-to-milliseconds-and-back-to-date-in-swift
extension Date {
    var millisecondsSince1970:Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }

    init(milliseconds:Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}

// Returns the systemName of the type of device
func getSFSymbolNameFromDeviceType(deviceType: DeviceType) -> String {
    switch (deviceType) {
        case .Unknown: return "questionmark.square.dashed"
        case .Desktop: return "desktopcomputer"
        case .Laptop: return "laptopcomputer"
        case .Phone: return "apps.iphone"
        case .Tablet: return "apps.ipad.landscape"
        default: return "questionmark.square.dashed"
    }
}

// Given a JSON String, returns a dictionary converted from the JSON String
func JSONStringtoDictionary(json: String) -> [String: String]? {
    if let jsonData = json.data(using: .utf8) {
        do {
            return try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String : String]
        } catch {
            print(error.localizedDescription)
        }
    }
    return nil
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
