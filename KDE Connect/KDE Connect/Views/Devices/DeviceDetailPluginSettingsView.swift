/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  DeviceDetailPluginSettingsView.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-06-19.
//

import SwiftUI

struct DeviceDetailPluginSettingsView: View {
    let detailsDeviceId: String
    // change to be part of init? perhapes for something like other views like remote input as well???
    @State var isPingEnabled: Bool = true
    @State var isShareEnabled: Bool = true
    @State var isFindMyPhoneEnabled: Bool = true
    @State var isBatteryEnabled: Bool = true
    @State var isClipboardEnabled: Bool = true
    @State var isRemoteInputEnabled: Bool = true
    @State var isRunCommandEnabled: Bool = true
    @State var isPresenterEnabled: Bool = true
    
    var body: some View {
        List {
            Section(header: Text("Enable/Disable Plugins"), footer: Text("You can enable or disable Plugins individually. Some Plugins have their own specific settings that can be found in their respective Views.")) {
                if backgroundService._devices[detailsDeviceId]!._plugins[.ping] != nil {
                    Toggle("Ping", isOn: $isPingEnabled)
                }
                if backgroundService._devices[detailsDeviceId]!._plugins[.share] != nil {
                    Toggle("Share/File Transfer", isOn: $isShareEnabled)
                }
                if backgroundService._devices[detailsDeviceId]!._plugins[.findMyPhoneRequest] != nil {
                    Toggle("Ring/Find My Phone", isOn: $isFindMyPhoneEnabled)
                }
                if backgroundService._devices[detailsDeviceId]!._plugins[.batteryRequest] != nil {
                    Toggle("Battery Status", isOn: $isBatteryEnabled)
                }
                if backgroundService._devices[detailsDeviceId]!._plugins[.clipboard] != nil {
                    Toggle("Clipboard Sync", isOn: $isClipboardEnabled)
                }
                if backgroundService._devices[detailsDeviceId]!._plugins[.mousePadRequest] != nil {
                    Toggle("Remote Input", isOn: $isRemoteInputEnabled)
                }
                if backgroundService._devices[detailsDeviceId]!._plugins[.runCommand] != nil {
                    Toggle("Run Command", isOn: $isRunCommandEnabled)
                }
                if backgroundService._devices[detailsDeviceId]!._plugins[.presenter] != nil {
                    Toggle("Slideshow Remote", isOn: $isPresenterEnabled)
                }
            }
        }
        .navigationTitle("Plugin Settings")
        .onChange(of: isPingEnabled) { value in
            backgroundService._devices[detailsDeviceId]!._pluginsEnableStatus[.ping] = value as NSNumber
        }
        .onChange(of: isShareEnabled) { value in
            backgroundService._devices[detailsDeviceId]!._pluginsEnableStatus[.share] = value as NSNumber
        }
        .onChange(of: isFindMyPhoneEnabled) { value in
            backgroundService._devices[detailsDeviceId]!._pluginsEnableStatus[.findMyPhoneRequest] = value as NSNumber
        }
        .onChange(of: isBatteryEnabled) { value in
            backgroundService._devices[detailsDeviceId]!._pluginsEnableStatus[.batteryRequest] = value as NSNumber
        }
        .onChange(of: isClipboardEnabled) { value in
            backgroundService._devices[detailsDeviceId]!._pluginsEnableStatus[.clipboard] = value as NSNumber
        }
        .onChange(of: isRemoteInputEnabled) { value in
            backgroundService._devices[detailsDeviceId]!._pluginsEnableStatus[.mousePadRequest] = value as NSNumber
        }
        .onChange(of: isRunCommandEnabled) { value in
            backgroundService._devices[detailsDeviceId]!._pluginsEnableStatus[.runCommand] = value as NSNumber
        }
        .onChange(of: isPresenterEnabled) { value in
            backgroundService._devices[detailsDeviceId]!._pluginsEnableStatus[.presenter] = value as NSNumber
        }
        .onAppear {
            updateValuesFromDevice()
        }
        .onDisappear {
            saveDeviceToUserDefaults(deviceId: detailsDeviceId)
            // TODO: find a better way to automatically update DevicesDetailView
            // most likely by making Device an ObservableObject
            // FIXME: remove the following workaround for triggering manual update
            // (also need to remove @ObservedObject viewModel from BatteryStatus)
            connectedDevicesViewModel.onDevicesListUpdated()
        }
    }
    
    func updateValuesFromDevice() {
        let fetchedDictionary = backgroundService.devices[detailsDeviceId]!._pluginsEnableStatus as! [NetworkPackage.`Type` : Bool]
        withAnimation {
            isPingEnabled = fetchedDictionary[.ping] ?? true
            isShareEnabled = fetchedDictionary[.share] ?? true
            isFindMyPhoneEnabled = fetchedDictionary[.findMyPhoneRequest] ?? true
            isBatteryEnabled = fetchedDictionary[.batteryRequest] ?? true
            isClipboardEnabled = fetchedDictionary[.clipboard] ?? true
            isRemoteInputEnabled = fetchedDictionary[.mousePadRequest] ?? true
            isRunCommandEnabled = fetchedDictionary[.runCommand] ?? true
            isPresenterEnabled = fetchedDictionary[.presenter] ?? true
        }
    }
}

//struct DeviceDetailPluginSettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//        DeviceDetailPluginSettingsView(detailsDeviceIndex: 0)
//    }
//}
