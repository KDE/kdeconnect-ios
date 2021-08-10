//
//  DevicesView.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-06-17.
//

import SwiftUI
// TODO: device can be discovered by other devices, but can't seem to discover other devices
struct DevicesView: View {
    // This is a bit redundent since it's basically just copy-and-pasting almost the exact
    // same view twice. But this is to get around what could be a bug. As
    // .navigationViewStyle(StackNavigationViewStyle())
    // Fixes the problem on iPhone BUT breaks side-by-side view support on iPad
    @Environment(\.horizontalSizeClass) var sizeClass
    
    @State var connectedDevicesIds: [String] = []
    @State var visibleDevicesIds: [String] = []
    @State var savedDevicesIds: [String] = []
    
    var body: some View {
        if (sizeClass == .compact) {
            NavigationView {
                List {
                    Section(header: Text("Connected Devices")) {
                        ForEach(connectedDevicesIds, id: \.self) { key in
                            NavigationLink(
                                // TODO: How do we know what to pass to the details view?
                                // Use teh "key" from ForEach aka device ID to get it from
                                // backgroundService's _devices dictionary for the value (Device class objects)
                                // DevicesDetailView(detailsDeviceId: String)
                                destination: PlaceHolderView(),
                                label: {
                                    HStack {
                                        Image(systemName: "wifi")
                                            .foregroundColor(.green)
                                            .font(.system(size: 21))
                                        VStack(alignment: .leading) {
                                            Text(connectedDevicesViewModel.connectedDevices[key] ?? "???")
                                                .font(.system(size: 18, weight: .bold))
                                            // TODO: Might want to add the device description as
                                            // id:desc dictionary?
                                            Text(key)
                                        }
                                    }
                                })
                        }
                    }
                    
                    Section(header: Text("Discoverable Devices")) {
                        ForEach(visibleDevicesIds, id: \.self) { key in
                            NavigationLink(
                                destination: PlaceHolderView(),
                                label: {
                                    HStack {
                                        Image(systemName: "badge.plus.radiowaves.right")
                                            .foregroundColor(.blue)
                                            .font(.system(size: 21))
                                        VStack(alignment: .leading) {
                                            Text(connectedDevicesViewModel.visibleDevices[key] ?? "???")
                                                .font(.system(size: 18, weight: .bold))
                                            Text("Tap to start pairing")
                                        }
                                    }
                                })
                        }
                    }

                    Section(header: Text("Remembered Devices")) {
                        ForEach(savedDevicesIds, id: \.self) { key in
                            NavigationLink(
                                destination: PlaceHolderView(),
                                label: {
                                    HStack {
                                        Image(systemName: "wifi.slash")
                                            .foregroundColor(.red)
                                            .font(.system(size: 21))
                                        VStack(alignment: .leading) {
                                            Text(connectedDevicesViewModel.savedDevices[key] ?? "???")
                                                .font(.system(size: 18, weight: .bold))
                                            // TODO: Might want to add the device description as
                                            // id:desc dictionary?
                                            Text(key)
                                        }
                                    }
                                })
                        }
                    }
                    
                }
                .navigationTitle("Devices")
                .navigationBarItems(trailing: {
                    Menu {
                        Button(action: {
                            //backgroundService.refreshDiscovery()
                            // TODO: is this the correct way to refresh list and discovery???
                            //backgroundService.refreshVisibleDeviceList()
                            //onDeviceListsRefreshed()
//                            print(connectedDevicesNames)
//                            print(visibleDevicesNames)
//                            print(savedDevicesNames)
                        }, label: {
                            HStack {
                                Text("Refresh Discovery")
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                        })
                        Button(action: {
                            // take to IP adding view
                        }, label: {
                            HStack {
                                Text("Configure Devices By IP")
                                Image(systemName: "network")
                            }
                        })
                        Button(action: {
                            // take to Trusted Networks View
                        }, label: {
                            HStack {
                                Text("Configure Trusted Networks")
                                Image(systemName: "lock.shield")
                            }
                        })
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }())
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .onAppear() {
                connectedDevicesViewModel.devicesView = self
                backgroundService._backgroundServiceDelegate = connectedDevicesViewModel
                //print(connectedDevicesNames)
                //print(visibleDevicesNames)
                //print(savedDevicesNames)
                backgroundService.refreshVisibleDeviceList()
                //onDeviceListsRefreshed()
            }
        } else { // iPad implementation goes here, without StackedNavigationStyle(), since that breaks iPad horizontal's split view (I think?)

        }
    }

    func onDeviceListRefreshedInsideView(vm : ConnectedDevicesViewModel) -> Void {
        connectedDevicesIds = Array(vm.connectedDevices.keys)//.sort
        visibleDevicesIds = Array(vm.visibleDevices.keys)//.sort
        savedDevicesIds = Array(vm.savedDevices.keys)//.sort
        
//        connectedDevicesId = [];
//        visibleDevicesId = [];
//        savedDevicesId = [];
//
//        for (key, _) in VM.connectedDevices {
//            connectedDevicesNames.append(key)
//        }
//        for (key, _) in VM.visibleDevices {
//            visibleDevicesNames.append(key)
//        }
//        for (key, _) in VM.savedDevices {
//            savedDevicesNames.append(key)
//        }
//
//        connectedDevicesId.sort()
//        visibleDevicesId.sort()
//        savedDevicesId.sort()
    }
    
}

//struct DevicesView_Previews: PreviewProvider {
//    static var previews: some View {
//        DevicesView()
//    }
//}
