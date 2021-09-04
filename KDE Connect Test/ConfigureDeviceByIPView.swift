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
    
    var body: some View {
        VStack {
            List {
                Section(header: Text("Direct Handshake Devices"), footer: Text("Add the local IP addresses of other devices here if they're having trouble appearing in the automatic discovery")) {
                    ForEach(selfDeviceDataForIPConfig.directIPs, id: \.self) { address in
                        Text(address)
                    }
                    .onDelete(perform: deleteAddress)
                }
            }
            
            Text("")
                .alert(isPresented: $showingAddNewIPAlert,
                       TextAlert(title: "Add new device via direct IP",
                                 message: "The local address of the other device can usually be found in its wifi settings") { result in
                        if let address = result {
                            // address was accepted
                            selfDeviceDataForIPConfig.directIPs.append(address)
                        } else {
                            // The alert was cancelled
                        }
                       })
        }
        .navigationTitle("Configure Devices By IP")
        .navigationBarItems(trailing: Button(action: {
            showingAddNewIPAlert = true
        }) {
            Image(systemName: "plus")
        })
        
    }
    func deleteAddress(at offsets: IndexSet) {
        selfDeviceDataForIPConfig.directIPs.remove(atOffsets: offsets)
    }
}

//struct ConfigureDeviceByIPView_Previews: PreviewProvider {
//    static var previews: some View {
//        ConfigureDeviceByIPView()
//    }
//}
