//
//  DevicesView.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-06-17.
//

import SwiftUI

struct DevicesView: View {
    // This is a bit redundent since it's basically just copy-and-pasting almost the exact
    // same view twice. But this is to get around what could be a bug. As
    // .navigationViewStyle(StackNavigationViewStyle())
    // Fixes the problem on iPhone BUT breaks side-by-side view support on iPad
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var body: some View {
        if (sizeClass == .compact) {
            NavigationView {
                List {
                    Section(header: Text("Connected Devices")) {
                        ForEach(testingOtherDevicesInfo.indices) { index in
                            if (testingOtherDevicesInfo[index].connectionStatus == "connected") {
                                NavigationLink(
                                    destination: DevicesDetailView(detailsDeviceIndex: index),
                                    label: {
                                        HStack {
                                            Image(systemName: otherDeviceSymbol[testingOtherDevicesInfo[index].connectionStatus]!)
                                                .foregroundColor(.green)
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
                    }
                    
                    Section(header: Text("Disconnected + Remembered Devices")) {
                        ForEach(testingOtherDevicesInfo.indices) { index in
                            if (testingOtherDevicesInfo[index].connectionStatus == "disconnected") {
                                NavigationLink(
                                    destination: DevicesDetailView(detailsDeviceIndex: index),
                                    label: {
                                        HStack {
                                            Image(systemName: otherDeviceSymbol[testingOtherDevicesInfo[index].connectionStatus]!)
                                                .foregroundColor(.red)
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
                    }
                    
                    Section(header: Text("Discoverable Devices")) {
                        ForEach(testingOtherDevicesInfo.indices) { index in
                            if (testingOtherDevicesInfo[index].connectionStatus == "discoverable") {
                                NavigationLink(
                                    destination: DevicesDetailView(detailsDeviceIndex: index),
                                    label: {
                                        HStack {
                                            Image(systemName: otherDeviceSymbol[testingOtherDevicesInfo[index].connectionStatus]!)
                                                .foregroundColor(.blue)
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
                    }
                    
                }
                .navigationTitle("Devices")
                .navigationBarItems(trailing: {
                    Button(action: {
                        linkProvider.onRefresh()
                    }, label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    })
                }())
            }
            .navigationViewStyle(StackNavigationViewStyle())
        } else {
            NavigationView {
                List {
                    Section(header: Text("Connected Devices")) {
                        ForEach(testingOtherDevicesInfo.indices) { index in
                            if (testingOtherDevicesInfo[index].connectionStatus == "connected") {
                                NavigationLink(
                                    destination: DevicesDetailView(detailsDeviceIndex: index),
                                    label: {
                                        HStack {
                                            Image(systemName: otherDeviceSymbol[testingOtherDevicesInfo[index].connectionStatus]!)
                                                .foregroundColor(.green)
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
                    }
                    
                    Section(header: Text("Disconnected + Remembered Devices")) {
                        ForEach(testingOtherDevicesInfo.indices) { index in
                            if (testingOtherDevicesInfo[index].connectionStatus == "disconnected") {
                                NavigationLink(
                                    destination: DevicesDetailView(detailsDeviceIndex: index),
                                    label: {
                                        HStack {
                                            Image(systemName: otherDeviceSymbol[testingOtherDevicesInfo[index].connectionStatus]!)
                                                .foregroundColor(.red)
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
                    }
                    
                    Section(header: Text("Discoverable Devices")) {
                        ForEach(testingOtherDevicesInfo.indices) { index in
                            if (testingOtherDevicesInfo[index].connectionStatus == "discoverable") {
                                NavigationLink(
                                    destination: DevicesDetailView(detailsDeviceIndex: index),
                                    label: {
                                        HStack {
                                            Image(systemName: otherDeviceSymbol[testingOtherDevicesInfo[index].connectionStatus]!)
                                                .foregroundColor(.blue)
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
                    }
                    
                }
                .navigationTitle("Devices")
                .navigationBarItems(trailing: {
                    Button(action: {
                        linkProvider.onRefresh()
                    }, label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    })
                }())
            }
        }
    }
}

//struct DevicesView_Previews: PreviewProvider {
//    static var previews: some View {
//        DevicesView()
//    }
//}
