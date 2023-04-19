/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 *                         2022 Apollo Zhu <public-apollonian@outlook.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  DeviceDiscoveryHelp.swift
//  KDE Connect
//
//  Created by Apollo Zhu on 5/11/22.
//

import SwiftUI

struct DeviceDiscoveryHelp: View {
    @EnvironmentObject private var selfDeviceData: SelfDeviceData
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("""
                    If KDE Connect is having trouble discovering other devices, you can try a combination of the following solutions:
                    
                    1. "Refresh Discovery" through the \(Image(systemName: "ellipsis.circle")) menu or pull to refresh the Devices list, on this and the other devices.
                    
                    2. Make sure the other devices are also running KDE Connect and are connected to the same network as this device.
                    
                    3. Manually add the other devices through the "Configure Devices By IP" option in the \(Image(systemName: "ellipsis.circle")) menu, and then "Refresh Discovery."
                    
                    4. Check other solutions on the User Manual, such as configuring the firewalls of the other devices:
                    
                    """, comment: "Please keep the newline at the end for the app layout things correctly.")
                    
                    Link("Troubleshooting",
                         destination: URL(string: "https://userbase.kde.org/KDEConnect#Troubleshooting")!)
                }
                .padding()
                .accessibilityAddTraits(selfDeviceData.isDebuggingDiscovery ? [] : .isButton)
                .accessibilityHint(
                    selfDeviceData.isDebuggingDiscovery
                    ? Text("Debugging device discovery")
                    : Text("Double tap to activate debugging device discovery")
                )
                .accessibilityAction {
                    enableDebuggingDiscovery()
                }
            }
            .navigationTitle("Device Discovery")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        if selfDeviceData.isDebuggingDiscovery {
                            Label("Done", systemImage: "hammer.fill")
                        } else {
                            Text("Done")
                        }
                    }
                }
            }
        }
        .onTapGesture(count: 10, perform: enableDebuggingDiscovery)
    }

    private func enableDebuggingDiscovery() {
        withAnimation {
            selfDeviceData.isDebugging = true
            selfDeviceData.isDebuggingDiscovery = true
        }
    }
}

struct DeviceDiscoveryHelp_Previews: PreviewProvider {
    static var previews: some View {
        DeviceDiscoveryHelp()
    }
}
