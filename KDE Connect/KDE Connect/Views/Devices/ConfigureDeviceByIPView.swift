/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  ConfigureDeviceByIPView.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-09-03.
//

#if !os(macOS)

import SwiftUI

struct ConfigureDeviceByIPView: View {
    @ObservedObject var kdeConnectSettingsForIPConfig: KdeConnectSettings = .shared
    @FocusState var focusedAddressID: UUID?
    
    struct DirectIPaddress: Identifiable {
        let id = UUID()
        var ip: String
    }
    
    @State var directIPs: [DirectIPaddress] = [] {
        didSet {
            kdeConnectSettingsForIPConfig.directIPs = directIPs.map(\.ip)
        }
    }

    var body: some View {
        List {
            Section(header: Text("Direct Handshake Devices"), footer: Text("Add the local IP addresses of other devices here if they're having trouble appearing in the automatic discovery")) {
                ForEach($directIPs) { $address in
                    TextField("Device IP", text: $address.ip)
                        .focused($focusedAddressID, equals: address.id)
                        .onSubmit {
                            withAnimation {
                                filterAddresses()
                            }
                            // filtering on iOS 14 will crash the app, and this
                            // back-port of onSubmit does nothing on iOS 14.
                        }
                }
                .onDelete(perform: deleteAddress)
            }
        }
        .navigationTitle("Configure Devices By IP")
        .navigationBarItems(trailing: Button {
            if let emptyIP = directIPs.first(where: { $0.ip.isEmpty }) {
                focusedAddressID = emptyIP.id
            } else {
                let newAddress = DirectIPaddress(ip: "")
                withAnimation {
                    directIPs.append(newAddress)
                }
                // iOS14+FocusState doesn't work if setting focus state inside withAnimation
                focusedAddressID = newAddress.id
            }
        } label: {
            Image(systemName: "plus")
        })
        .onDisappear(perform: filterAddresses)
        .onAppear {
            directIPs = kdeConnectSettingsForIPConfig.directIPs.map { DirectIPaddress(ip: $0) }
            filterAddresses()
        }
    }
    
    func deleteAddress(at offsets: IndexSet) {
        directIPs.remove(atOffsets: offsets)
    }
    
    func filterAddresses() {
        directIPs = directIPs.filter { !$0.ip.isEmpty }
    }
}

// struct ConfigureDeviceByIPView_Previews: PreviewProvider {
//     static var previews: some View {
//         ConfigureDeviceByIPView()
//     }
// }

#endif
