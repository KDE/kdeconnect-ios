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
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        TabView {
            NavigationView {
                DevicesView()
                
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
            
            FilesTab()
                .introspectSplitViewController { splitViewController in
                    splitViewController.preferredSplitBehavior = .tile
                    splitViewController.preferredDisplayMode = .oneBesideSecondary
                }
                .tabItem {
                    Label("Files", systemImage: "folder")
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
        .introspectTabBarController { tabBarController in
            // Ref: https://www.reddit.com/r/SwiftUI/comments/p8obef/comment/h9t8trs/
            if #available(iOS 15.0, *) {
                // No scroll and TabView conflict in previous iOS versions
                if horizontalSizeClass == .regular {
                    // Conflict only when there is SplitView (i.e., regular horizontalSizeClass)
                    // Ref: https://www.hackingwithswift.com/quick-start/swiftui/how-to-create-different-layouts-using-size-classes
                    let opaqueBar = UITabBarAppearance()
                    opaqueBar.configureWithOpaqueBackground()
                    tabBarController.tabBar.standardAppearance = opaqueBar
                    tabBarController.tabBar.scrollEdgeAppearance = opaqueBar
                } else {
                    let newTabBar = UITabBar()
                    tabBarController.tabBar.standardAppearance = newTabBar.standardAppearance
                    tabBarController.tabBar.scrollEdgeAppearance = newTabBar.scrollEdgeAppearance
                }
            }
        }
    }
}

struct TabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AlertManager())
            .environmentObject(SelfDeviceData.shared)
            .environmentObject(connectedDevicesViewModel)
    }
}
