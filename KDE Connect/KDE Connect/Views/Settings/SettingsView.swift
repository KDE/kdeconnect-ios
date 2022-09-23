//
//  SettingsView.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-06-17.
//

#if !os(macOS)

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var kdeConnectSettingsForSettings: KdeConnectSettings = .shared
    
    var body: some View {
        List {
            // These could go in sections to give them each descriptions and space
            Section(header: Text("General")) {
                NavigationLink(destination: SettingsDeviceNameView(deviceName: $kdeConnectSettingsForSettings.deviceName)) {
                    AccessibleHStack {
                        Label("Device Name", systemImage: DeviceType.current.sfSymbolName)
                            .labelStyle(.accessibilityTitleOnly)
                            .accentColor(.primary)
                        Spacer()
                        Text(kdeConnectSettingsForSettings.deviceName)
                            .foregroundColor(.secondary)
                    }
                }
                
                NavigationLink(destination: SettingsChosenThemeView(chosenTheme: $kdeConnectSettingsForSettings.chosenTheme)) {
                    AccessibleHStack {
                        Label("App Theme", systemImage: "lightbulb")
                            .labelStyle(.accessibilityTitleOnly)
                            .accentColor(.primary)
                        Spacer()
                        kdeConnectSettingsForSettings.chosenTheme.text
                            .foregroundColor(.secondary)
                    }
                }
                
                if UIApplication.shared.supportsAlternateIcons {
                    NavigationLink {
                        AppIconPicker()
                    } label: {
                        AccessibleHStack {
                            Label("App Icon", systemImage: "app")
                                .labelStyle(.accessibilityTitleOnly)
                                .accentColor(.primary)
                            Spacer()
                            kdeConnectSettingsForSettings.appIcon.name
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                NavigationLink {
                    SettingsAdvancedView()
                } label: {
                    Label("Advanced Settings", systemImage: "wrench.and.screwdriver")
                        .labelStyle(.accessibilityTitleOnly)
                        .accentColor(.primary)
                }
                
                NavigationLink {
                    SettingsBackgroundView()
                } label: {
                    Label("Background Execution", systemImage: "pin")
                        .labelStyle(.accessibilityTitleOnly)
                        .accentColor(.primary)
                }
            }
            
            Section(header: Text("Information")) {
                NavigationLink {
                    SettingsAboutView()
                } label: {
                    Label("About", systemImage: "info.circle")
                        .labelStyle(.accessibilityTitleOnly)
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
                    .labelStyle(.accessibilityTitleOnly)
                    .accentColor(.primary)
                }
            }
        }
        .navigationTitle("Settings")
    }
}

// struct SettingsView_Previews: PreviewProvider {
//     static var previews: some View {
//         SettingsView()
//     }
// }

#endif
