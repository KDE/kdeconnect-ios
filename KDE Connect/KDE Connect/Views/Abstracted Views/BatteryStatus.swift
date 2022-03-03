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
    let battery: Battery?
    // FIXME: remove the following workaround for triggering manual update
    // when DeviceDetailPluginSettingsView.onDisappear workaround is removed
    @ObservedObject var viewModel = connectedDevicesViewModel
    let validBatteryContent: (Battery) -> ValidBatteryStatusContent
    
    init(device: Device,
         @ViewBuilder validBatteryContent: @escaping (Battery) -> ValidBatteryStatusContent) {
        self.device = device
        self.battery = device._plugins[.batteryRequest] as? Battery
        self.validBatteryContent = validBatteryContent
    }
    
    var body: some View {
        if let battery = battery {
            BatteryObserving(
                battery: battery,
                isEnabled: device._pluginsEnableStatus[.batteryRequest] as? Bool,
                validBatteryContent: validBatteryContent
            )
        } else {
            Self.makeNoBatteryView()
        }
    }
    
    private struct BatteryObserving: View {
        @ObservedObject var battery: Battery
        let isEnabled: Bool?
        let validBatteryContent: (Battery) -> ValidBatteryStatusContent
        
        var body: some View {
            if isEnabled == nil || battery.remoteChargeLevel == 0 {
                makeNoBatteryView()
            } else if isEnabled == false {
                Text("Battery Plugin Disabled")
                    .font(.footnote)
            } else {
                validBatteryContent(battery)
            }
        }
    }
    
    private static func makeNoBatteryView() -> some View {
        Text("No battery detected in device")
            .font(.footnote)
    }
}

//struct BatteryStatus_Previews: PreviewProvider {
//    static var previews: some View {
//        BatteryStatus()
//    }
//}
