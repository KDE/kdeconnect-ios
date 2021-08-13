//
//  Backend.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-08-04.
//

import Foundation
import UIKit
// A place to house objects for global usage by the rest of the app
// Background Service provider, bridged from Obj-C codebase
let backgroundService: BackgroundService = BackgroundService()

// ViewModel object for devices-related functionalities
// TODO: Should this be kept global or local to DevicesView()? Reference might break if this is
// global but making it local to DevicesView() would likely make it harder to access values in it
// We'll finish developing everything else and see if anything other than DevicesView() needs it.
// I think we probably do since the Unpair function is now in the details view instead of the
// DevicesView()
let connectedDevicesViewModel: ConnectedDevicesViewModel = ConnectedDevicesViewModel()

let haptics = UIImpactFeedbackGenerator(style: .rigid)

// Global functions
func saveFile(fileData: Data, filename: String) -> Bool {
    let fileManager = FileManager.default
    do {
        let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false) // gets URL of app's document directory
        let fileURL = documentDirectory.appendingPathComponent(filename) // adds new file's name to URL
        //print(fileURL.absoluteString)
        try fileData.write(to: fileURL) // and save!
        return true
    } catch {
        print(error)
    }
    return false
}
