//
//  SettingsActionView.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-06-17.
//

import SwiftUI

struct SettingsDeviceNameView: View {
    @Binding var deviceName: String
    
    var body: some View {
        VStack {
            TextField("The name of the device as recognized by KDE Connect", text: $deviceName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Spacer()
        }
        .navigationTitle("Device Name")
    }
}

struct SettingsActionView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsDeviceNameView(deviceName: .constant("iPhone 7"))
    }
}
