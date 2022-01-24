//
//  SettingsView.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-06-17.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var selfDeviceDataForSettings: SelfDeviceData = selfDeviceData
    
    var body: some View {
        List {
            // These could go in sections to give them each descriptions and space
            Section(header: Text("Host Device Settings")) {
                NavigationLink(destination: SettingsDeviceNameView(deviceName: $selfDeviceDataForSettings.deviceName)) {
                    HStack {
                        Label("Device Name", systemImage: "iphone")
                            .accentColor(.primary)
                        Spacer()
                        Text(selfDeviceData.deviceName)
                            .foregroundColor(.secondary)
                    }
                }
                
                NavigationLink(destination: SettingsChosenThemeView(chosenTheme: $selfDeviceDataForSettings.chosenTheme)) {
                    HStack {
                        Label("App Theme", systemImage: "lightbulb")
                            .accentColor(.primary)
                        Spacer()
                        Text(selfDeviceData.chosenTheme)
                            .foregroundColor(.secondary)
                    }
                }
                
                NavigationLink(destination: SettingsAdvancedView()) {
                    Label("Advanced Settings", systemImage: "wrench.and.screwdriver")
                        .accentColor(.primary)
                }
            }

            Section(header: Text("Information")) {
                NavigationLink(destination: SettingsAboutView()) {
                    Label("About", systemImage: "info.circle")
                        .accentColor(.primary)
                }
            }
        }
        .environment(\.defaultMinListRowHeight, 50) // TODO: make this dynamic with GeometryReader???
        .navigationTitle("Settings")
    }
}

//struct SettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//        SettingsView()
//    }
//}
