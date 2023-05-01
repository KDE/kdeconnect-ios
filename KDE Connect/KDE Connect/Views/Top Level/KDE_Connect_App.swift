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

import UIKit
import SwiftUI

// Intentional naming
// swiftlint:disable:next type_name
@main struct KDE_Connect_App: App {
    @ObservedObject var selfDeviceDataForTopLevel: SelfDeviceData = .shared
    @StateObject var alertManager: AlertManager = AlertManager()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(selfDeviceDataForTopLevel.chosenTheme)
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
                .environmentObject(SelfDeviceData.shared)
                .environmentObject(connectedDevicesViewModel)
                .environmentObject(alertManager)
                .alert(
                    alertManager.currentAlert.title,
                    isPresented: $alertManager.alertPresent,
                    actions: alertManager.currentAlert.buttons,
                    message: alertManager.currentAlert.content
                )
        }
    }
}
