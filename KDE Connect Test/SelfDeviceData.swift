//
//  DeviceData.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-06-17.
//

import Foundation
import Combine

class SelfDeviceData: ObservableObject {
    @Published var deviceName: String {
        didSet {
            UserDefaults.standard.set(deviceName, forKey: "deviceName")
        }
    }
    
    @Published var chosenTheme: String {
        didSet {
            UserDefaults.standard.set(chosenTheme, forKey: "chosenTheme")
        }
    }
    
    init() {
        self.deviceName = UserDefaults.standard.object(forKey: "deviceName") as? String ?? ""
        self.chosenTheme = UserDefaults.standard.object(forKey: "chosenTheme") as? String ?? "System Default"
    }
}
