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
                        Text("App Theme")
                        Spacer()
                        Text(selfDeviceData.chosenTheme)
                            .font(.system(size: 12))
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
