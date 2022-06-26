/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  ContentView.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-06-17.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var alertManager: AlertManager

    var body: some View {
        TabView {
            NavigationView {
                DevicesView()
                    .environmentObject(alertManager)
                    .environmentObject(SelfDeviceData.shared)
                
                Text("Select a device from the Devices list to start.")
                    .navigationTitle("KDE Connect")
            }
            .introspectSplitViewController { splitViewController in
                splitViewController.preferredSplitBehavior = .tile
                splitViewController.preferredDisplayMode = .oneBesideSecondary
            }
            .tabItem {
                Label("Devices", systemImage: "laptopcomputer.and.iphone")
            }
            
            NavigationView {
                SettingsView()
                
                EmptyView()
                    .navigationTitle("KDE Connect")
            }
            .introspectSplitViewController { splitViewController in
                splitViewController.preferredSplitBehavior = .tile
                splitViewController.preferredDisplayMode = .oneBesideSecondary
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}

struct TabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
