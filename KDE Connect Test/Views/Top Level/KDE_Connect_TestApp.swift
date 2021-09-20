//
//  KDE_Connect_TestApp.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-06-17.
//

import SwiftUI

@main struct KDE_Connect_TestApp: App {
    @ObservedObject var selfDeviceDataForTopLevel: SelfDeviceData = selfDeviceData
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme((selfDeviceDataForTopLevel.chosenTheme == "System Default") ? nil : appThemes[selfDeviceDataForTopLevel.chosenTheme])
                .onAppear {
                    backgroundService.startDiscovery()
                    motionManager.gyroUpdateInterval = 0.1
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // In case the app's been chilling suspended for a long time, upon returning ask for updates to all devices's battery statuses
                    requestBatteryStatusAllDevices()
                }
        }
    }
}
