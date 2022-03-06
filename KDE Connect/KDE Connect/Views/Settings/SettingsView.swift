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
            Section(header: Text("General")) {
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
                
                if UIApplication.shared.supportsAlternateIcons {
                    NavigationLink {
                        AppIconPicker()
                            .environmentObject(selfDeviceDataForSettings)
                    } label: {
                        HStack {
                            Label("App Icon", systemImage: "app")
                                .accentColor(.primary)
                            Spacer()
                            selfDeviceDataForSettings.appIcon.name
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                NavigationLink(destination: SettingsAdvancedView()) {
                    Label("Advanced Settings", systemImage: "wrench.and.screwdriver")
                        .accentColor(.primary)
                }
            }
            
            Section(header: Text("Information")) {
                NavigationLink {
                    SettingsAboutView()
                        .environmentObject(selfDeviceDataForSettings)
                } label: {
                    Label("About", systemImage: "info.circle")
                        .accentColor(.primary)
                }
                NavigationLink(destination: FeaturesList()) {
                    Label {
                        Text("Features")
                    } icon: {
                        if #available(iOS 15, *) {
                            Image(systemName: "checklist")
                        } else {
                            Image(systemName: "scroll")
                        }
                    }
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
