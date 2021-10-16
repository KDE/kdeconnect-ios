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
            Section(header: Text("Host Device Settings")) {
                NavigationLink(
                    destination: SettingsDeviceNameView(deviceName: $selfDeviceDataForSettings.deviceName),
                    label: {
                        HStack {
                            Image(systemName: "iphone")
                            Text("Device Name")
                            Spacer()
                            Text(selfDeviceData.deviceName)
                                .font(.caption)
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
                                .font(.caption)
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
            
            Section(header: Text("External Links")) {
                HStack {
                    Image(systemName: "books.vertical")
                    Link("Wiki & User's Manual", destination: URL(string: "https://userbase.kde.org/KDEConnect")!)
                }
                
                HStack {
                    Image(systemName: "ladybug")
                    Link("Report Bug", destination: URL(string: "https://bugs.kde.org/enter_bug.cgi?product=kdeconnect&component=ios-application")!)
                }
                
                HStack {
                    Image(systemName: "dollarsign.square")
                    Link("Donate", destination: URL(string: "https://kde.org/community/donations/")!)
                }
                
                HStack {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                    Link("Source Code", destination: URL(string: "https://invent.kde.org/network/kdeconnect-ios")!)
                }
                
                HStack {
                    Image(systemName: "magazine")
                    Link("Licenses", destination: URL(string: "https://invent.kde.org/network/kdeconnect-ios/-/blob/master/License.md")!)
                }
            }
            
        }
        .environment(\.defaultMinListRowHeight, 50) // TODO: make this dynamic with GeometryReader???
        .navigationTitle("Settings")
    }
}

//struct SettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//        SettingsView()
//    }
//}
