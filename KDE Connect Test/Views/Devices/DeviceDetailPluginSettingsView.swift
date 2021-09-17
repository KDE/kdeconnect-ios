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
            Text("You can enable or disable Plugins individually. Some Plugins have their own specific settings that can be found in their respective Views.")
            if ((backgroundService._devices[detailsDeviceId] as! Device)._plugins[PACKAGE_TYPE_PING] != nil) {
                Toggle("Ping", isOn: $isPingEnabled)
            }
            if ((backgroundService._devices[detailsDeviceId] as! Device)._plugins[PACKAGE_TYPE_SHARE] != nil) {
                Toggle("Share/File Transfer", isOn: $isShareEnabled)
            }
            if ((backgroundService._devices[detailsDeviceId] as! Device)._plugins[PACKAGE_TYPE_FINDMYPHONE_REQUEST] != nil) {
                Toggle("Ring/Find My Phone", isOn: $isFindMyPhoneEnabled)
            }
            if ((backgroundService._devices[detailsDeviceId] as! Device)._plugins[PACKAGE_TYPE_BATTERY_REQUEST] != nil) {
                Toggle("Battery Status", isOn: $isBatteryEnabled)
            }
            if ((backgroundService._devices[detailsDeviceId] as! Device)._plugins[PACKAGE_TYPE_CLIPBOARD] != nil) {
                Toggle("Clipboard Sync", isOn: $isClipboardEnabled)
            }
            if ((backgroundService._devices[detailsDeviceId] as! Device)._plugins[PACKAGE_TYPE_MOUSEPAD_REQUEST] != nil) {
                Toggle("Remote Input", isOn: $isRemoteInputEnabled)
            }
            if ((backgroundService._devices[detailsDeviceId] as! Device)._plugins[PACKAGE_TYPE_RUNCOMMAND] != nil) {
                Toggle("Run Command", isOn: $isRunCommandEnabled)
            }
            if ((backgroundService._devices[detailsDeviceId] as! Device)._plugins[PACKAGE_TYPE_PRESENTER] != nil) {
                Toggle("Slideshow Remote", isOn: $isPresenterEnabled)
            }
        }
        .navigationTitle("Plugin Settings")
        .onChange(of: isPingEnabled, perform: { value in
            (backgroundService._devices[detailsDeviceId] as! Device)._pluginsEnableStatus[PACKAGE_TYPE_PING] = value
        })
        .onChange(of: isShareEnabled, perform: { value in
            (backgroundService._devices[detailsDeviceId] as! Device)._pluginsEnableStatus[PACKAGE_TYPE_SHARE] = value
        })
        .onChange(of: isFindMyPhoneEnabled, perform: { value in
            (backgroundService._devices[detailsDeviceId] as! Device)._pluginsEnableStatus[PACKAGE_TYPE_FINDMYPHONE_REQUEST] = value
        })
        .onChange(of: isBatteryEnabled, perform: { value in
            (backgroundService._devices[detailsDeviceId] as! Device)._pluginsEnableStatus[PACKAGE_TYPE_BATTERY_REQUEST] = value
        })
        .onChange(of: isClipboardEnabled, perform: { value in
            (backgroundService._devices[detailsDeviceId] as! Device)._pluginsEnableStatus[PACKAGE_TYPE_CLIPBOARD] = value
        })
        .onChange(of: isRemoteInputEnabled, perform: { value in
            (backgroundService._devices[detailsDeviceId] as! Device)._pluginsEnableStatus[PACKAGE_TYPE_MOUSEPAD_REQUEST] = value
        })
        .onChange(of: isRunCommandEnabled, perform: { value in
            (backgroundService._devices[detailsDeviceId] as! Device)._pluginsEnableStatus[PACKAGE_TYPE_RUNCOMMAND] = value
        })
        .onChange(of: isPresenterEnabled, perform: { value in
            (backgroundService._devices[detailsDeviceId] as! Device)._pluginsEnableStatus[PACKAGE_TYPE_PRESENTER] = value
        })
        .onAppear() {
            updateValuesFromDevice()
        }
        .onDisappear() {
            connectedDevicesViewModel.reRenderCurrDeviceDetailsView(deviceId: detailsDeviceId)
            connectedDevicesViewModel.reRenderDeviceView()
            saveDeviceToUserDefaults(deviceId: detailsDeviceId)
        }
    }
    
    func updateValuesFromDevice() -> Void {
        let fetchedDictionary: [String : Bool] = (backgroundService._devices[detailsDeviceId] as! Device)._pluginsEnableStatus as! [String : Bool]
        withAnimation {
            isPingEnabled = fetchedDictionary[PACKAGE_TYPE_PING] ?? true
            isShareEnabled = fetchedDictionary[PACKAGE_TYPE_SHARE] ?? true
            isFindMyPhoneEnabled = fetchedDictionary[PACKAGE_TYPE_FINDMYPHONE_REQUEST] ?? true
            isBatteryEnabled = fetchedDictionary[PACKAGE_TYPE_BATTERY_REQUEST] ?? true
            isClipboardEnabled = fetchedDictionary[PACKAGE_TYPE_CLIPBOARD] ?? true
            isRemoteInputEnabled = fetchedDictionary[PACKAGE_TYPE_MOUSEPAD_REQUEST] ?? true
            isRunCommandEnabled = fetchedDictionary[PACKAGE_TYPE_RUNCOMMAND] ?? true
            isPresenterEnabled = fetchedDictionary[PACKAGE_TYPE_PRESENTER] ?? true
        }
    }
}

//struct DeviceDetailPluginSettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//        DeviceDetailPluginSettingsView(detailsDeviceIndex: 0)
//    }
//}
