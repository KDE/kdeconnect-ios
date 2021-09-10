//
//  KDE_Connect_TestApp.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-06-17.
//

/**
 TO-Dos:
  - Single file transfer is not reliable, sometimes the connection just drops. Errors on Anroid, investigating Android code CompositeUpload to try to figure out what's going on: seems like we're sending ID Packet for file transfer connections, fixed, will see what happens
 
  - Multi-file transfer is indeed using a new connection for each file transferred, so should be do-able once we fix the issue with single file tranfer?
 
  - Figure out how to store host device's cert in keychains, remote devices's certs can just be stored in the Device objects
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
