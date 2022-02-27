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
            Section(header: Text("DANGEROUS OPTIONS"), footer: Text("The options above are irreversible and require a complete app restart to take effect.")) {
                Button {
                    notificationHapticsGenerator.notificationOccurred(.warning)
                    certificateService.deleteAllItemsFromKeychain()
                    UserDefaults.standard.removeObject(forKey: "savedDevices")
                } label: {
                    HStack {
                        Image(systemName: "delete.right")
                        VStack(alignment: .leading) {
                            Text("Erase saved devices cache")
                                .font(.headline)
                            Text("If there are phantom devices or something just doesn't behave correctly, erasing all saved devices data might fix it. Requires the app to be fully restarted.")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.red)
                }
                
                Button {
                    notificationHapticsGenerator.notificationOccurred(.warning)
                    certificateService.deleteHostCertificateFromKeychain()
                } label: {
                    HStack {
                        Image(systemName: "delete.right")
                        VStack(alignment: .leading) {
                            Text("Delete host certificate")
                                .font(.headline)
                            Text("Delete the host's certificate and re-generate it upon restart. Requires the app to be fully restarted. NOTE: this will make the device unable to connect with previously connected devices. You must unpair this device from the other remote devices and pair them again.")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Advanced Settings")
    }
}

//struct SettingsAdvancedView_Previews: PreviewProvider {
//    static var previews: some View {
//        SettingsAdvancedView()
//    }
//}
