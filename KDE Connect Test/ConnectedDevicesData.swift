//
//  ConnectedDevicesData.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-06-17.
//

import Foundation
import Combine

class ConnectedDeviceData: Identifiable {
    let id: UUID
    var connectedDeviceName: String
    var connectedDeviceDescription: String
    var connectionStatus: Bool
    var pluginSettings: [String : Bool]
    
    init(connectedDeviceName: String, connectedDeviceDescription: String,
         connectionStatus: Bool, pluginSettings: [String : Bool]) {
        self.id = UUID()
        self.connectedDeviceName = connectedDeviceName
        self.connectedDeviceDescription = connectedDeviceDescription
        self.connectionStatus = connectionStatus
        self.pluginSettings = pluginSettings
    }
}

let testingConnectedDevicesInfo: [ConnectedDeviceData] = [ConnectedDeviceData(connectedDeviceName: "Pixel 3a XL", connectedDeviceDescription: "Other phone", connectionStatus: true, pluginSettings: [:]), ConnectedDeviceData(connectedDeviceName: "Galaxy Tab S6 Lite", connectedDeviceDescription: "Video, reading, and sketching tablet", connectionStatus: false, pluginSettings: [:])]
