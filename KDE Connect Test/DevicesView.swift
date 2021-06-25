//
//  DevicesView.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-06-17.
//

import SwiftUI

struct DevicesView: View {
    var body: some View {
        NavigationView {
            List {
                ForEach(testingConnectedDevicesInfo.indices) { index in
                    NavigationLink(
                        destination: DevicesDetailView(detailsDeviceIndex: index),
                        label: {
                            HStack {
                                Image(systemName: (testingConnectedDevicesInfo[index].connectionStatus ? "wifi" : "wifi.slash"))
                                    .foregroundColor(testingConnectedDevicesInfo[index].connectionStatus ? .green : .red)
                                    .font(.system(size: 23))
                                VStack(alignment: .leading) {
                                    Text(testingConnectedDevicesInfo[index].connectedDeviceName)
                                        .font(.system(size: 20, weight: .bold))
                                    Text(testingConnectedDevicesInfo[index].connectedDeviceDescription)
                                }
                            }
                    })
                }
            }
            .navigationTitle("Devices")
        }
    }
}

//struct DevicesView_Previews: PreviewProvider {
//    static var previews: some View {
//        DevicesView()
//    }
//}
