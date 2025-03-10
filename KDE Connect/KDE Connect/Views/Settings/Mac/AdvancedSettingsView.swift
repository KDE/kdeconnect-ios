//
//  AdvancedSettingsView.swift
//  KDE Connect
//
//  Created by Ruixuan Tu on 2022/05/12.
//

import SwiftUI

struct AdvancedSettingsView: View {
    var body: some View {
        VStack {
            Spacer()
            
            Button {
                backgroundService.stopDiscovery()
                CertificateService.shared.deleteAllItemsFromKeychain()
                UserDefaults.standard.removeObject(forKey: "savedDevices")
                exit(0)
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
            }.buttonStyle(.plain)
            
            Spacer()
            
            Button {
                backgroundService.stopDiscovery()
                CertificateService.deleteHostCertificateFromKeychain()
                exit(0)
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
            }.buttonStyle(.plain)
            
            Spacer()
            
            Button {
                backgroundService.stopDiscovery()
                // ref: https://stackoverflow.com/questions/43402032/how-to-remove-all-userdefaults-data-swift
                let domain = Bundle.main.bundleIdentifier!
                UserDefaults.standard.removePersistentDomain(forName: domain)
                UserDefaults.standard.synchronize()
                print("deleted settings, remaining: \(Array(UserDefaults.standard.dictionaryRepresentation().keys).count)")
                CertificateService.shared.deleteAllItemsFromKeychain()
            } label: {
                HStack {
                    Image(systemName: "delete.right")
                    VStack(alignment: .leading) {
                        Text("Forget all")
                            .font(.headline)
                        Text("Delete all saved settings and devices. Requires the app to be fully restarted.")
                            .font(.caption)
                    }
                }
                .foregroundColor(.red)
            }.buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
        }.padding(.all)
    }
}

struct AdvancedSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedSettingsView()
    }
}
