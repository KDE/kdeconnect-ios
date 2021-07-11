//
//  ConnectedDevicesData.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-06-17.
//

import Foundation
import Combine

class OtherDeviceData: Identifiable {
    let id: UUID
    var connectedDeviceName: String
    var connectedDeviceDescription: String
    var connectionStatus: String
    var pluginSettings: [String : Bool]
    
    init(connectedDeviceName: String, connectedDeviceDescription: String,
         connectionStatus: String, pluginSettings: [String : Bool]) {
        self.id = UUID()
        self.connectedDeviceName = connectedDeviceName
        self.connectedDeviceDescription = connectedDeviceDescription
        self.connectionStatus = connectionStatus
        self.pluginSettings = pluginSettings
    }
}

let otherDeviceSymbol: [String : String] = ["connected" : "wifi", "disconnected" : "wifi.slash", "discoverable" : "badge.plus.radiowaves.right"]

let testingOtherDevicesInfo: [OtherDeviceData] = [OtherDeviceData(connectedDeviceName: "Pixel 3a XL", connectedDeviceDescription: "Other phone", connectionStatus: "connected", pluginSettings: [:]), OtherDeviceData(connectedDeviceName: "Galaxy Tab S6 Lite", connectedDeviceDescription: "Video, reading, and sketching tablet", connectionStatus: "disconnected", pluginSettings: [:]), OtherDeviceData(connectedDeviceName: "Slimbook 15", connectedDeviceDescription: "Tap to start pairing", connectionStatus: "discoverable", pluginSettings: [:])]
