//
//  SettingsActionView.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-06-17.
//

import SwiftUI

struct SettingsDeviceNameView: View {
    @Binding var deviceName: String
    @FocusState private var focused = false
    
    var body: some View {
        List {
            Section {
                TextField("Device name", text: $deviceName)
                    .focused($focused)
            } footer: {
                Text("The name of the device as recognized by KDE Connect")
            }
        }
        .onAppear {
            focused = true
        }
        .navigationTitle("Device Name")
    }
}

struct SettingsActionView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsDeviceNameView(deviceName: .constant("iPhone 7"))
    }
}
