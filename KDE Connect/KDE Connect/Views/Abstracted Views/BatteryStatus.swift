/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  BatteryStatus.swift
//  KDE Connect
//
//  Created by Apollo Zhu on 12/5/21.
//

import SwiftUI

struct BatteryStatus<ValidBatteryStatusContent: View>: View {
    let device: Device
    @ObservedObject var battery: Battery
    // FIXME: remove the following workaround for triggering manual update
    // when DeviceDetailPluginSettingsView.onDisappear workaround is removed
    @ObservedObject var viewModel = connectedDevicesViewModel
    let validBatteryContent: (Battery) -> ValidBatteryStatusContent
    
    init(device: Device,
         @ViewBuilder validBatteryContent: @escaping (Battery) -> ValidBatteryStatusContent) {
        self.device = device
        self.battery = device._plugins[.batteryRequest] as! Battery
        self.validBatteryContent = validBatteryContent
    }
    
    var batteryPluginStatus: Bool? {
        device._pluginsEnableStatus[.batteryRequest] as? Bool
    }
    
    var body: some View {
        if batteryPluginStatus == nil || battery.remoteChargeLevel == 0 {
            Text("No battery detected in device")
                .font(.footnote)
        } else if batteryPluginStatus == false {
            Text("Battery Plugin Disabled")
                .font(.footnote)
        } else {
            validBatteryContent(battery)
        }
    }
}

//struct BatteryStatus_Previews: PreviewProvider {
//    static var previews: some View {
//        BatteryStatus()
//    }
//}
