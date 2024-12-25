/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  KDE_Connect_App.swift
//  KDE Connect
//
//  Created by Lucas Wang on 2021-06-17.
//

#if !os(macOS)
import UIKit
#else
import UserNotifications
#endif
import SwiftUI

// Intentional naming
// swiftlint:disable:next type_name
@main struct KDE_Connect_App: App {
    @ObservedObject var kdeConnectSettingsForTopLevel: KdeConnectSettings = .shared
#if !os(macOS)
    @StateObject var alertManager: AlertManager = AlertManager()
#else
    @StateObject var notificationManager: NotificationManager = NotificationManager()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State var disabledByNotGrantedNotificationPermission: Bool = false
    @State var showingHelpWindow: Bool = false
    
    func requestNotification() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if error != nil {
                self.disabledByNotGrantedNotificationPermission = true
            } else {
                self.disabledByNotGrantedNotificationPermission = false
            }
        }
    }
#endif
    
    var body: some Scene {
#if !os(macOS)
        WindowGroup {
            MainTabView()
                .preferredColorScheme(kdeConnectSettingsForTopLevel.chosenTheme)
                .onAppear {
#if DEBUG
                    if ProcessInfo.processInfo.arguments.contains("setupScreenshotDevices") {
                        UIPreview.setupFakeDevices()
                    }
#endif
                    backgroundService.startDiscovery()
                    motionManager.gyroUpdateInterval = 0.025
                    
                    UIApplication.shared.isIdleTimerDisabled = true
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // In case the app's been chilling suspended for a long time,
                    // upon returning ask for updates to all devices's battery statuses
                    // broadcastBatteryStatusAllDevices()
                    // requestBatteryStatusAllDevices()

                    // However, non of the links are kept alive in background
                    backgroundService.refreshDiscovery()
                }
                .onReceive(NotificationCenter.default
                    .publisher(for: UIApplication
                        .didEnterBackgroundNotification)
                ) { _ in
                    // Aggressively terminate the socket is the best way
                    // to prevent weird broken pipe/invalid socket issue
                    backgroundService.stopDiscovery()
                }
                .environmentObject(KdeConnectSettings.shared)
                .environmentObject(connectedDevicesViewModel)
                .environmentObject(alertManager)
                .alert(
                    alertManager.currentAlert.title,
                    isPresented: $alertManager.alertPresent,
                    actions: alertManager.currentAlert.buttons,
                    message: alertManager.currentAlert.content
                )
        }
#else
        WindowGroup("Connect", id: "connect") {
            if !self.disabledByNotGrantedNotificationPermission {
                MainView(showingHelpWindow: self.$showingHelpWindow)
                    .preferredColorScheme(kdeConnectSettingsForTopLevel.chosenTheme)
                    .onAppear {
                        NSApplication.shared.applicationIconImage = NSImage(named: (kdeConnectSettingsForTopLevel.appIcon.rawValue ?? "AppIcon"))
                        requestNotification()
                        backgroundService.startDiscovery()
                        requestBatteryStatusAllDevices()
                    }
                    .environmentObject(notificationManager)
                    .onReceive(NotificationCenter.default.publisher(for: NSApplication.willUpdateNotification)) { _ in
                        requestNotification()
                    }
            } else {
                AskNotificationView()
                    .preferredColorScheme(kdeConnectSettingsForTopLevel.chosenTheme)
                    .onReceive(NotificationCenter.default.publisher(for: NSApplication.willUpdateNotification)) { _ in
                        requestNotification()
                    }
            }
        }
        .commands {
            CommandMenu("Devices") {
                if !self.disabledByNotGrantedNotificationPermission {
                    Button("Refresh Discovery") {
                        MainView.mainViewSingleton?.refreshDiscoveryAndList()
                    }
                } else {
                    Label("Refresh Discovery", systemImage: "")
                }
                Button("Show Received Files in Finder") {
                    let fileManager = FileManager.default
                    do {
                        // see Share plugin
                        let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                        NSWorkspace.shared.open(documentDirectory)
                    } catch {
                        print("Error showing received files in Finder \(error)")
                    }
                }
            }
        }
        .windowStyle(.hiddenTitleBar)
    
        WindowGroup("Help", id: "help") {
            HelpView(showingHelpWindow: self.$showingHelpWindow)
                .preferredColorScheme(kdeConnectSettingsForTopLevel.chosenTheme)
        }
        .windowStyle(.hiddenTitleBar)
        
        Settings {
            if !self.disabledByNotGrantedNotificationPermission {
                SettingsView()
                    .preferredColorScheme(kdeConnectSettingsForTopLevel.chosenTheme)
                    .environmentObject(kdeConnectSettingsForTopLevel)
            } else {
                AskNotificationView()
                    .preferredColorScheme(kdeConnectSettingsForTopLevel.chosenTheme)
                    .frame(width: 450, height: 250)
            }
        }
#endif
    }
}
