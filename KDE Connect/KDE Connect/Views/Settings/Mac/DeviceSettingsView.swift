//
//  DeviceSettingsView.swift
//  KDE Connect
//
//  Created by Ruixuan Tu on 2022/05/12.
//

#if os(macOS)

import SwiftUI
import UserNotifications

struct DeviceSettingsView: View {
    @Binding var deviceName: String
    @Binding var grantedNotificationPermission: Bool
//    @State private var deviceType: String = "Laptop"
    
    struct StatusIndicator: View {
        @Binding var isOn: Bool
        
        var body: some View {
            Circle()
                .fill(isOn ? .green : .red)
                .frame(width: 10, height: 10)
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Device Name:")
                TextField("", text: self.$deviceName)
                    .onChange(of: self.deviceName) { _ in
                        MainView.mainViewSingleton?.refreshDiscoveryAndList()
                    }
            }
            HStack {
                Text("Out-App Notification:")
                StatusIndicator(isOn: $grantedNotificationPermission)
                Spacer()
            }
//            HStack {
//                Picker(selection: $deviceType, label: Text("Device Type:")) {
//                    Text("Laptop").tag("Laptop")
//                    Text("PC").tag("PC")
//                }
//                .pickerStyle(RadioGroupPickerStyle())
//                .horizontalRadioGroupLayout()
//                Spacer()
//            }
        }.padding(.all)
    }
}

struct DeviceSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceSettingsView(deviceName: .constant("My Laptop"), grantedNotificationPermission: .constant(false))
    }
}

#endif
