//
//  PrefPane.swift
//  KDE Connect
//
//  Created by Ruixuan Tu on 2022/05/12.
//

#if os(macOS)

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var kdeConnectSettings: KdeConnectSettings = KdeConnectSettings.shared
    @Binding private var grantedNotificationPermission: Bool
    
    init(grantedNotificationPermission: Binding<Bool>) {
        self._grantedNotificationPermission = grantedNotificationPermission
    }
    
    var body: some View {
        TabView {
            DeviceSettingsView(deviceName: $kdeConnectSettings.deviceName, grantedNotificationPermission: $grantedNotificationPermission)
                .tabItem {
                    Label("Device", systemImage: "display")
                }
            PeerSettingsView(directIPs: $kdeConnectSettings.directIPs)
                .tabItem {
                    Label("Peer", systemImage: "laptopcomputer.and.iphone")
                }
            AppSettingsView(chosenTheme: $kdeConnectSettings.chosenTheme, appIcon: $kdeConnectSettings.appIcon)
                .tabItem {
                    Label("Application", systemImage: "app")
                }
            AdvancedSettingsView()
                .tabItem {
                    Label("Advanced", systemImage: "wrench.and.screwdriver")
                }
        }
        .frame(width: 450, height: 250)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(grantedNotificationPermission: .constant(false))
    }
}

#endif
