//
//  KDE_Connect_TestApp.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-06-17.
//

/**
 TO-Dos:
  - When unpair is initiated from remote, the device does not get removed from the "saved devices" list, I don't know why but neither the unpairDevice() from backgroundService nor the device's own unpair() is getting called
 
  - Figure out how to store host device's cert in keychains, remote devices's certs can just be stored in the Device objects
 
  - Implement switching ports if file transfer hits an occupied port
 */

import SwiftUI

@main struct KDE_Connect_TestApp: App {
    @ObservedObject var selfDeviceDataForTopLevel: SelfDeviceData = selfDeviceData
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme((selfDeviceDataForTopLevel.chosenTheme == "System Default") ? nil : appThemes[selfDeviceDataForTopLevel.chosenTheme])
                .onAppear {
                    backgroundService.startDiscovery()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // In case the app's been chilling suspended for a long time, upon returning ask for updates to all devices's battery statuses
                    requestBatteryStatusAllDevices()
                }
        }
    }
}
