//
//  SettingsAdvancedView.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-09-12.
//

import SwiftUI

struct SettingsAdvancedView: View {
    var body: some View {
        VStack {
            Section(footer: Text("If there are phantom devices or something just doesn't behave correctly, erasing all saved devices data might fix it")) {
                Button(action: {
                    notificationHapticsGenerator.notificationOccurred(.warning)
                    UserDefaults.standard.removeObject(forKey: "savedDevices")
                }, label: {
                    HStack {
                        Text("Erase saved devices cache")
                        Image(systemName: "delete.left")
                    }
                })
            }
        }
    }
}

//struct SettingsAdvancedView_Previews: PreviewProvider {
//    static var previews: some View {
//        SettingsAdvancedView()
//    }
//}
