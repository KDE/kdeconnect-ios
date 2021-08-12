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
    
    @State private var connectedDevicesIds: [String] = []
    @State private var visibleDevicesIds: [String] = []
    @State private var savedDevicesIds: [String] = []
    
    @State var currPairingDeviceId: String?
    @State private var showingOnPairRequestAlert: Bool = false
    @State private var showingOnPairTimeoutAlert: Bool = false
    @State private var showingOnPairSuccessAlert: Bool = false
    @State private var showingOnPairRejectedAlert: Bool = false
    @State private var showingOnSelfPairOutgoingRequestAlert: Bool = false
    @State private var showingOnSelectSavedDeviceAlert: Bool = false
    
    @ObservedObject var localNotificationService = LocalNotificationService()
    
    var body: some View {
        if (sizeClass == .compact) {
            NavigationView {
                VStack {
                    List {
                        Section(header: Text("Connected Devices")) {
                            ForEach(connectedDevicesIds, id: \.self) { key in
                                NavigationLink(
                                    // TODO: How do we know what to pass to the details view?
                                    // Use the "key" from ForEach aka device ID to get it from
                                    // backgroundService's _devices dictionary for the value (Device class objects)
                                    destination: DevicesDetailView(detailsDeviceId: key),
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
                                Button(action: {
                                    currPairingDeviceId = key
                                    showingOnSelfPairOutgoingRequestAlert = true
                                }) {
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
                                    
                                }
                            }
                        }
                        
                        Section(header: Text("Remembered Devices")) {
                            ForEach(savedDevicesIds, id: \.self) { key in
                                Button(action: {
                                    currPairingDeviceId = key
                                    showingOnSelectSavedDeviceAlert = true
                                }) {
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
                                }
                            }
                        }
                        
                    }
                    
                    Text("")
                        .alert(isPresented: $showingOnPairRequestAlert) { // TODO: Might want to add a "pairing in progress" UI element?
                            Alert(title: Text("Incoming Pairing Request"),
                                  message: Text("\(connectedDevicesViewModel.visibleDevices[currPairingDeviceId!] ?? "ERROR") wants to pair with this device"),
                                  primaryButton: .cancel(Text("Do Not Pair")),
                                  secondaryButton: .default(
                                    Text("Pair")
                                        .foregroundColor(.green)
                                  ) {
                                    backgroundService.pairDevice(currPairingDeviceId)
                                    //currPairingDeviceId = nil
                                  }
                            )
                        }
                    
                    Text("")
                        .alert(isPresented: $showingOnPairTimeoutAlert) {
                            Alert(title: Text("Pairing Timed Out"),
                                  message: Text("Pairing with \((backgroundService._devices[currPairingDeviceId!] as! Device)._name) failed"),
                                  dismissButton: .default(Text("OK"), action: {
                                    currPairingDeviceId = nil
                                  })
                            )
                        }
                    
                    Text("")
                        .alert(isPresented: $showingOnPairSuccessAlert) {
                            Alert(title: Text("Pairing Complete"),
                                  message: Text("Pairing with \((backgroundService._devices[currPairingDeviceId!] as! Device)._name) succeeded"),
                                  dismissButton: .default(Text("Nice"), action: {
                                    currPairingDeviceId = nil
                                  })
                            )
                        }
                    
                    Text("")
                        .alert(isPresented: $showingOnPairRejectedAlert) {
                            Alert(title: Text("Pairing Rejected"),
                                  message: Text("Pairing with \((backgroundService._devices[currPairingDeviceId!] as! Device)._name) failed"),
                                  dismissButton: .default(Text("OK"), action: {
                                    currPairingDeviceId = nil
                                  })
                            )
                        }
                    
                    Text("")
                        .alert(isPresented: $showingOnSelfPairOutgoingRequestAlert) {
                            Alert(title: Text("Initiate Pairing?"),
                                  message: Text("Request to pair with \(connectedDevicesViewModel.visibleDevices[currPairingDeviceId!] ?? "ERROR")?"),
                                  primaryButton: .cancel(Text("Do Not Pair")),
                                  secondaryButton: .default(
                                    Text("Pair")
                                        .foregroundColor(.green)
                                  ) {
                                    backgroundService.pairDevice(currPairingDeviceId)
                                    //currPairingDeviceId = nil
                                  }
                            )
                        }
                    
                    Text("")
                        .alert(isPresented: $showingOnSelectSavedDeviceAlert) {
                            Alert(title: Text("Device Offline"),
                                  message: Text("The paired device \(currPairingDeviceId!) is not reachable. Make sure it is connected to the same network as this device."),
                                  dismissButton: .default(Text("OK"), action: {
                                    currPairingDeviceId = nil
                                  })
                            )
                        }
                    
                }
                .navigationTitle("Devices")
                .navigationBarItems(trailing: {
                    Menu {
                        Button(action: {
                            refreshDiscoveryAndList()
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
                if (connectedDevicesViewModel.devicesView == nil) {
                    connectedDevicesViewModel.devicesView = self
                }
                if (backgroundService._backgroundServiceDelegate == nil) {
                    backgroundService._backgroundServiceDelegate = connectedDevicesViewModel
                }
                refreshDiscoveryAndList()
            }
        } else { // iPad implementation goes here, without StackedNavigationStyle(), since that breaks iPad horizontal's split view (I think?)

        }
    }

    func onPairRequestInsideView(_ deviceId: String!) -> Void {
        currPairingDeviceId = deviceId
//        self.localNotificationService.sendNotification(title: "Incoming Pairing Request", subtitle: nil, body: "\(connectedDevicesViewModel.visibleDevices[currPairingDeviceId!] ?? "ERROR") wants to pair with this device", launchIn: 2)
        showingOnPairRequestAlert = true
    }
    
    func onPairTimeoutInsideView(_ deviceId: String!) -> Void {
        //currPairingDeviceId = nil
        showingOnPairTimeoutAlert = true
    }
    
    func onPairSuccessInsideView(_ deviceId: String!) -> Void {
        showingOnPairSuccessAlert = true
        connectedDevicesViewModel.onDeviceListRefreshed()
    }
    
    func onPairRejectedInsideView(_ deviceId: String!) -> Void {
        showingOnPairRejectedAlert = true
    }
    
    func onDeviceListRefreshedInsideView(vm : ConnectedDevicesViewModel) -> Void {
        connectedDevicesIds = Array(vm.connectedDevices.keys)//.sort
        visibleDevicesIds = Array(vm.visibleDevices.keys)//.sort
        savedDevicesIds = Array(vm.savedDevices.keys)//.sort
    }
    
    func refreshDiscoveryAndList() {
        let group = DispatchGroup()
        group.enter()
        backgroundService.refreshDiscovery()
        group.leave()
        group.notify(queue: DispatchQueue.main) {
            backgroundService.refreshVisibleDeviceList()
        }
    }
    
}

//struct DevicesView_Previews: PreviewProvider {
//    static var previews: some View {
//        DevicesView()
//    }
//}
