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
                            Label("Device Name", systemImage: "iphone")
                                .accentColor(.primary)
                            Spacer()
                            Text(selfDeviceData.deviceName)
                                .foregroundColor(.secondary)
                        }
                    })
                
                NavigationLink(
                    destination: SettingsChosenThemeView(chosenTheme: $selfDeviceDataForSettings.chosenTheme),
                    label: {
                        HStack {
                            Label("App Theme", systemImage: "lightbulb")
                                .accentColor(.primary)
                            Spacer()
                            Text(selfDeviceData.chosenTheme)
                                .foregroundColor(.secondary)
                        }
                    })
                
                NavigationLink(
                    destination: SettingsAdvancedView(),
                    label: {
                        Label("Advanced Settings", systemImage: "wrench.and.screwdriver")
                            .accentColor(.primary)
                    })
            }
            
            Section(header: Text("External Links")) {
                Label {
                    Link("Wiki & User's Manual", destination: URL(string: "https://userbase.kde.org/KDEConnect")!)
                } icon: {
                    Image(systemName: "books.vertical")
                        .accentColor(.primary)
                }
                
                Label {
                    Link("Report Bug", destination: URL(string: "https://bugs.kde.org/enter_bug.cgi?product=kdeconnect&component=ios-application")!)
                } icon: {
                    Image(systemName: "ladybug")
                        .accentColor(.primary)
                }
                
                Label {
                    Link("Donate", destination: URL(string: "https://kde.org/community/donations/")!)
                } icon: {
                    Image(systemName: "dollarsign.square")
                        .accentColor(.primary)
                }
                
                Label {
                    Link("Source Code", destination: URL(string: "https://invent.kde.org/network/kdeconnect-ios")!)
                } icon: {
                    if #available(iOS 15, *) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .accentColor(.primary)
                    } else {
                        Image(systemName: "chevron.left.slash.chevron.right")
                    }
                }
                
                Label {
                    Link("Licenses", destination: URL(string: "https://invent.kde.org/network/kdeconnect-ios/-/blob/master/License.md")!)
                } icon: {
                    if #available(iOS 15, *) {
                        Image(systemName: "magazine")
                            .accentColor(.primary)
                    } else {
                        Image(systemName: "text.book.closed")
                    }
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
