//
//  SettingsView.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-06-17.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var selfDeviceDataForSettings: SelfDeviceData = selfDeviceData
    
    var body: some View {
        List {
            // These could go in sections to give them each descriptions and space
            NavigationLink(
                destination: SettingsDeviceNameView(deviceName: $selfDeviceDataForSettings.deviceName),
                label: {
                    HStack {
                        Image(systemName: "iphone")
                        Text("Device Name")
                        Spacer()
                        Text(selfDeviceData.deviceName)
                            .font(.system(size: 12))
                    }
                })
            
            NavigationLink(
                destination: SettingsChosenThemeView(chosenTheme: $selfDeviceDataForSettings.chosenTheme),
                label: {
                    HStack {
                        Image(systemName: "lightbulb")
                        Text("App Theme")
                        Spacer()
                        Text(selfDeviceData.chosenTheme)
                            .font(.system(size: 12))
                    }
                })
            
            NavigationLink(
                destination: SettingsAdvancedView(),
                label: {
                    HStack {
                        Image(systemName: "wrench.and.screwdriver") //exclamationmark.triangle
                        Text("Advanced Settings")
                    }
                })
        }
        .navigationTitle("Settings")
    }
}

//struct SettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//        SettingsView()
//    }
//}
