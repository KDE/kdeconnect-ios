//
//  DevicesView.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-06-17.
//

import SwiftUI

struct DevicesView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var body: some View {
        if (sizeClass == .compact) {
            NavigationView {
                List {
                    ForEach(testingOtherDevicesInfo.indices) { index in
                        NavigationLink(
                            destination: DevicesDetailView(detailsDeviceIndex: index),
                            label: {
                                HStack {
                                    Image(systemName: otherDeviceSymbol[testingOtherDevicesInfo[index].connectionStatus]!)
                                        .foregroundColor((testingOtherDevicesInfo[index].connectionStatus == "disconnected") ? .red : .green)
                                        .font(.system(size: 21))
                                    VStack(alignment: .leading) {
                                        Text(testingOtherDevicesInfo[index].connectedDeviceName)
                                            .font(.system(size: 18, weight: .bold))
                                        Text(testingOtherDevicesInfo[index].connectedDeviceDescription)
                                    }
                                }
                            })
                    }
                }
                .navigationTitle("Devices")
            }
            .navigationViewStyle(StackNavigationViewStyle())
        } else {
            NavigationView {
                List {
                    ForEach(testingOtherDevicesInfo.indices) { index in
                        NavigationLink(
                            destination: DevicesDetailView(detailsDeviceIndex: index),
                            label: {
                                HStack {
                                    Image(systemName: otherDeviceSymbol[testingOtherDevicesInfo[index].connectionStatus]!)
                                        .foregroundColor((testingOtherDevicesInfo[index].connectionStatus == "disconnected") ? .red : .green)
                                        .font(.system(size: 21))
                                    VStack(alignment: .leading) {
                                        Text(testingOtherDevicesInfo[index].connectedDeviceName)
                                            .font(.system(size: 18, weight: .bold))
                                        Text(testingOtherDevicesInfo[index].connectedDeviceDescription)
                                    }
                                }
                            })
                    }
                }
                .navigationTitle("Devices")
            }
        }
    }
}

//struct DevicesView_Previews: PreviewProvider {
//    static var previews: some View {
//        DevicesView()
//    }
//}
