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
                    (avaliablePlugins[PACKAGE_TYPE_BATTERY] as! Battery).startBatteryMonitoring()
                    backgroundService.startDiscovery()
                }
        }
    }
}
