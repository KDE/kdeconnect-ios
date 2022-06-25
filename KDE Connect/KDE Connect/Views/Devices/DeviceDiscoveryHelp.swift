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
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("""
                    If KDE Connect is having trouble discovering other devices, you can try a combination of the following solutions:
                    
                    1. "Refresh Discovery" through the \(Image(systemName: "ellipsis.circle")) menu or pull to refresh the Devices list.
                    
                    2. Make sure the other devices are also running KDE Connect and are connected to the same network as this device.
                    
                    3. Manually add the other devices through the "Configure Devices By IP" in the \(Image(systemName: "ellipsis.circle")) menu.
                    
                    4. Check other solutions on the User Manual, such as configuring the firewalls of the other devices:
                    
                    """, comment: "Please keep the newline at the end for the app layout things correctly.")
                    
                    Link("Troubleshooting",
                         destination: URL(string: "https://userbase.kde.org/KDEConnect#Troubleshooting")!)
                }
                .padding()
            }
            .navigationTitle("Device Discovery")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("Done")
                    }
                }
            }
        }
    }
}

struct DeviceDiscoveryHelp_Previews: PreviewProvider {
    static var previews: some View {
        DeviceDiscoveryHelp()
    }
}
