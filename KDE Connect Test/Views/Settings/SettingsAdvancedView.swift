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
                certificateService.deleteAllItemsFromKeychain()
                UserDefaults.standard.removeObject(forKey: "savedDevices")
            }, label: {
                HStack {
                    Image(systemName: "delete.right")
                    VStack(alignment: .leading) {
                        Text("Erase saved devices cache")
                            .font(.system(size: 18, weight: .semibold))
                        Text("If there are phantom devices or something just doesn't behave correctly, erasing all saved devices data might fix it. Requires the app to be fully restarted.")
                            .font(.system(size: 12))
                    }
                }
            })
            
            Button(action: {
                notificationHapticsGenerator.notificationOccurred(.warning)
                certificateService.deleteHostCertificateFromKeychain()
            }, label: {
                HStack {
                    Image(systemName: "delete.right")
                    VStack(alignment: .leading) {
                        Text("Delete host certificate")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Delete the host's certificate and re-generate it upon restart. Requires the app to be fully restarted. NOTE: this will make the device unable to connect with previously connected devices. You must unpair this device from the other remote devices and pair them again.")
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
