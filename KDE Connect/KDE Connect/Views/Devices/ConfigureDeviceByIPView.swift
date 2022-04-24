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

import SwiftUI

struct ConfigureDeviceByIPView: View {
    @ObservedObject var selfDeviceDataForIPConfig: SelfDeviceData = selfDeviceData
    @State var showingAddNewIPAlert: Bool = false
    
    struct DirectIPaddress: Identifiable {
        let id = UUID()
        var ip: String
    }
    
    @State var directIPs: [DirectIPaddress] = [] {
        didSet {
            selfDeviceDataForIPConfig.directIPs = directIPs.map(\.ip)
        }
    }

    var body: some View {
        List {
            Section(header: Text("Direct Handshake Devices"), footer: Text("Add the local IP addresses of other devices here if they're having trouble appearing in the automatic discovery")) {
                ForEach($directIPs) { $address in
                    TextField("Device IP", text: $address.ip) {
                        withAnimation {
                            filterAddresses()
                        }
                    }
                }
                .onDelete(perform: deleteAddress)
            }
        }
        .navigationTitle("Configure Devices By IP")
        .navigationBarItems(trailing: Button {
            if !directIPs.contains(where: { $0.ip.isEmpty }) {
                let newAddress = DirectIPaddress(ip: "")
                withAnimation {
                    directIPs.append(newAddress)
                }
            }
        } label: {
            Image(systemName: "plus")
        })
        .onDisappear(perform: filterAddresses)
        .onAppear {
            directIPs = selfDeviceDataForIPConfig.directIPs.map { DirectIPaddress(ip: $0) }
            filterAddresses()
        }
    }
    
    func deleteAddress(at offsets: IndexSet) {
        directIPs.remove(atOffsets: offsets)
    }
    
    func filterAddresses() {
        directIPs = directIPs.filter { $0.ip != "" }
    }
}

//struct ConfigureDeviceByIPView_Previews: PreviewProvider {
//    static var previews: some View {
//        ConfigureDeviceByIPView()
//    }
//}
