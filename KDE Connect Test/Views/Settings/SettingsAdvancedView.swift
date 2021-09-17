//
//  SettingsAdvancedView.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-09-12.
//

import SwiftUI

struct SettingsAdvancedView: View {
    var body: some View {
        List {
            Button(action: {
                notificationHapticsGenerator.notificationOccurred(.warning)
                UserDefaults.standard.removeObject(forKey: "savedDevices")
            }, label: {
                HStack {
                    Image(systemName: "delete.right")
                    VStack(alignment: .leading) {
                        Text("Erase saved devices cache")
                            .font(.system(size: 18, weight: .semibold))
                        Text("If there are phantom devices or something just doesn't behave correctly, erasing all saved devices data might fix it")
                            .font(.system(size: 12))
                    }
                }
            })
        }
        .navigationTitle("Advanced Settings")
    }
}

//struct SettingsAdvancedView_Previews: PreviewProvider {
//    static var previews: some View {
//        SettingsAdvancedView()
//    }
//}
