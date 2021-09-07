//
//  Backend.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-08-04.
//

import Foundation
import UIKit
import AVFoundation
// A place to house functions and variables for global usage by the rest of the app

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
let haptics = UIImpactFeedbackGenerator(style: .rigid)

// System sounds definitions, for a list of all IDs, see
// https://github.com/TUNER88/iOSSystemSoundsLibrary
let soundSMSReceived: SystemSoundID = 1003
let soundCalendarAlert: SystemSoundID = 1005
let soundAudioToneBusy: SystemSoundID = 1070
let soundMailReceived: SystemSoundID = 1000

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
