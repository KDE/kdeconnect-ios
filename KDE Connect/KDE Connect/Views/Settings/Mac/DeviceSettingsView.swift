//
//  DeviceSettingsView.swift
//  KDE Connect
//
//  Created by Ruixuan Tu on 2022/05/12.
//

#if os(macOS)

import SwiftUI

struct DeviceSettingsView: View {
    @Binding var deviceName: String
//    @State private var deviceType: String = "Laptop"
    
    var body: some View {
        VStack {
            HStack {
                Text("Device Name:")
                TextField("", text: self.$deviceName)
                    .onChange(of: self.deviceName) { _ in
                        MainView.mainViewSingleton?.refreshDiscoveryAndList()
                    }
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
        DeviceSettingsView(deviceName: .constant("My Laptop"))
    }
}

#endif
