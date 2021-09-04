//
//  ContentView.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-06-17.
//

import SwiftUI

struct MainTabView: View {
    // This is a bit redundent since it's basically just copy-and-pasting almost the exact
    // same view twice. But this is to get around what could be a bug. As
    // .navigationViewStyle(StackNavigationViewStyle())
    // Fixes the problem on iPhone BUT breaks side-by-side view support on iPad
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var body: some View {
        TabView {
            if (sizeClass == .compact) {
                NavigationView {
                    DevicesView()
                }
                .tabItem {
                    Label("Devices", systemImage: "laptopcomputer.and.iphone")
                }
                .navigationViewStyle(StackNavigationViewStyle())
                
                NavigationView {
                    SettingsView()
                }
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .navigationViewStyle(StackNavigationViewStyle())
            } else {
                NavigationView {
                    DevicesView()
                }
                .tabItem {
                    Label("Devices", systemImage: "laptopcomputer.and.iphone")
                }
                
                NavigationView {
                    SettingsView()
                }
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
    }
}

//struct TabView_Previews: PreviewProvider {
//    static var previews: some View {
//        MainTabView()
//    }
//}
