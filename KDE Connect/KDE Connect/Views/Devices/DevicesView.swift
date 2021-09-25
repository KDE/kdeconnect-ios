//
//  DevicesView.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-06-17.
//

import SwiftUI
import AVFoundation

struct DevicesView: View {
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
    @State private var showingPingAlert: Bool = false
    @State private var showingFindMyPhoneAlert: Bool = false
    @State private var showingFileReceivedAlert: Bool = false
    
    @State private var showingConfigureDevicesByIPView: Bool = false
    
    @State var viewUpdate: Bool = false
    
    //@ObservedObject var localNotificationService = LocalNotificationService()
    
    var body: some View {
        VStack {
            List {
                Section(header: Text("Connected Devices")) {
                    if (connectedDevicesIds.isEmpty) {
                        Text("No devices currently connected.\nConnected devices will appear here. Please Refresh Discovery if a saved device is already online but not shown here.")
                    } else {
                        ForEach(connectedDevicesIds, id: \.self) { key in
                            NavigationLink(
                                // How do we know what to pass to the details view?
                                // Use the "key" from ForEach aka device ID to get it from
                                // backgroundService's _devices dictionary for the value (Device class objects)
                                destination: DevicesDetailView(detailsDeviceId: key),
                                label: {
                                    HStack {
                                        Image(systemName: "wifi")
                                            .foregroundColor(.green)
                                            .font(.system(size: 23))
                                        VStack(alignment: .leading) {
                                            HStack {
                                                Text(connectedDevicesViewModel.connectedDevices[key] ?? "???")
                                                    .font(.system(size: 19, weight: .bold))
                                                if (backgroundService._devices[key as Any] != nil) {
                                                    Image(systemName: getSFSymbolNameFromDeviceType(deviceType: (backgroundService._devices[key as Any] as! Device)._type))
                                                        .font(.system(size: 19))
                                                }
                                            }
                                            if ((backgroundService._devices[key as Any] as! Device)._pluginsEnableStatus[PACKAGE_TYPE_BATTERY_REQUEST] == nil) {
                                                Text("No battery detected in device")
                                                    .font(.system(size: 13))
                                            } else if (!((backgroundService._devices[key as Any] as! Device)._pluginsEnableStatus[PACKAGE_TYPE_BATTERY_REQUEST] as! Bool)) {
                                                Text("Battery Plugin Disabled")
                                                    .font(.system(size: 13))
                                            } else {
                                                HStack {
                                                    Image(systemName: ((backgroundService._devices[key as Any] as! Device)._plugins[PACKAGE_TYPE_BATTERY_REQUEST] as! Battery).getSFSymbolNameFromBatteryStatus())
                                                        .font(.system(size: 13))
                                                        .foregroundColor(((backgroundService._devices[key as Any] as! Device)._plugins[PACKAGE_TYPE_BATTERY_REQUEST] as! Battery).getSFSymbolColorFromBatteryStatus())
                                                    Text("\(((backgroundService._devices[key as Any] as! Device)._plugins[PACKAGE_TYPE_BATTERY_REQUEST] as! Battery).remoteChargeLevel)%")
                                                        .font(.system(size: 13))
                                                }
                                            }
                                            // TODO: Might want to add the device description as
                                            // id:desc dictionary?
                                            //Text(key)
                                        }
                                    }
                                })
                        }
                    }
                }
                
                Section(header: Text("Discoverable Devices")) {
                    if (visibleDevicesIds.isEmpty) {
                        Text("No devices discoverable on this network.\nMake sure to Refresh Discovery and check that the other devices are also running KDE Connect & are connected to the same network as this device.")
                    } else {
                        ForEach(visibleDevicesIds, id: \.self) { key in
                            Button(action: {
                                currPairingDeviceId = key
                                showingOnSelfPairOutgoingRequestAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "badge.plus.radiowaves.right")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 23))
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Text(connectedDevicesViewModel.visibleDevices[key] ?? "???")
                                                .font(.system(size: 19, weight: .bold))
                                            if (backgroundService._devices[key as Any] != nil) {
                                                Image(systemName: getSFSymbolNameFromDeviceType(deviceType: (backgroundService._devices[key as Any] as! Device)._type))
                                                    .font(.system(size: 19))
                                            }
                                        }
                                        Text("Tap to start pairing")
                                            .font(.system(size: 15))
                                    }
                                }
                                
                            }
                        }
                    }
                }
                
                Section(header: Text("Remembered Devices")) {
                    if (savedDevicesIds.isEmpty) {
                        Text("No remembered devices.\nDevices that were previously connected will appear here.")
                    } else {
                        ForEach(savedDevicesIds, id: \.self) { key in
                            Button(action: {
                                currPairingDeviceId = key
                                showingOnSelectSavedDeviceAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "wifi.slash")
                                        .foregroundColor(.red)
                                        .font(.system(size: 23))
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Text(connectedDevicesViewModel.savedDevices[key] ?? "???")
                                                .font(.system(size: 19, weight: .bold))
                                            Image(systemName: getSFSymbolNameFromDeviceType(deviceType: (backgroundService._devices[key as Any] as! Device)._type))
                                                .font(.system(size: 19))
                                        }
                                        // TODO: Might want to add the device description as
                                        // id:desc dictionary?
                                        //Text(key)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deleteDevice)
                    }
                }
            }
            .refreshable() {
                refreshDiscoveryAndList()
            }
            .environment(\.defaultMinListRowHeight, 60) // TODO: make this dynamic with GeometryReader???
            .alert("Incoming Pairing Request", isPresented: $showingOnPairRequestAlert) { // TODO: Might want to add a "pairing in progress" UI element?
                Button("Do Not Pair", role: .cancel) {}
                Button("Pair") {
                    backgroundService.pairDevice(currPairingDeviceId)
                }
                    .foregroundColor(.green)
            } message: {
                if (currPairingDeviceId != nil) {
                    Text("\(connectedDevicesViewModel.visibleDevices[currPairingDeviceId!] ?? "ERROR") wants to pair with this device")
                }
            }
            .alert("Pairing Complete", isPresented: $showingOnPairSuccessAlert) {
                Button("Nice", role: .cancel) {
                    currPairingDeviceId = nil
                }
            } message: {
                if (currPairingDeviceId != nil) {
                    Text("Pairing with \((backgroundService._devices[currPairingDeviceId!] as! Device)._name) succeeded")
                }
            }
            .alert("Initiate Pairing?", isPresented: $showingOnSelfPairOutgoingRequestAlert) {
                Button("OK", role: .cancel) {}
                Button("Pair") {
                    backgroundService.pairDevice(currPairingDeviceId)
                }
                    .foregroundColor(.green)
            } message: {
                if (currPairingDeviceId != nil) {
                    Text("Request to pair with \(connectedDevicesViewModel.visibleDevices[currPairingDeviceId!] ?? "ERROR")?")
                }
            }
            .alert("Device Offline", isPresented: $showingOnSelectSavedDeviceAlert) {
                Button("OK", role: .cancel) {
                    currPairingDeviceId = nil
                }
            } message: {
                if (currPairingDeviceId != nil && connectedDevicesViewModel.savedDevices[currPairingDeviceId!] != nil) {
                    Text("The paired device \(connectedDevicesViewModel.savedDevices[currPairingDeviceId!]!) is not reachable. Make sure it is connected to the same network as this device.")
                }
            }
            .alert("Pairing Timed Out", isPresented: $showingOnPairTimeoutAlert) {
                Button("OK", role: .cancel) {
                    currPairingDeviceId = nil
                }
            } message: {
                if (currPairingDeviceId != nil) {
                    Text("Pairing with \((backgroundService._devices[currPairingDeviceId!] as! Device)._name) failed")
                }
            }
            .alert("Pairing Rejected", isPresented: $showingOnPairRejectedAlert) {
                Button("OK", role: .cancel) {
                    currPairingDeviceId = nil
                }
            } message: {
                if (currPairingDeviceId != nil) {
                    Text("Pairing with \((backgroundService._devices[currPairingDeviceId!] as! Device)._name) failed")
                }
            }
            .alert("Ping!", isPresented: $showingPingAlert) {} message: {
                Text("Ping received from a connected device.")
            }
            .alert("Find My Phone Mode", isPresented: $showingFindMyPhoneAlert) {
                Button("I FOUND IT!", role: .cancel) {}
            } message: {
                Text("Find My Phone initiated from a remote device")
            }
            
            NavigationLink(destination: ConfigureDeviceByIPView(), isActive: $showingConfigureDevicesByIPView) {
                EmptyView()
            }
            // This is an invisible view using changes in viewUpdate to force SwiftUI to re-render the entire screen. We want this because the battery information is NOT a @State variables, as such in order for updates to actually register, we need to force the view to re-render
            Text(viewUpdate ? "True" : "False")
                .frame(width: 0, height: 0)
                .opacity(0)
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
                    showingConfigureDevicesByIPView = true
                }, label: {
                    HStack {
                        Text("Configure Devices By IP")
                        Image(systemName: "network")
                    }
                })
                //TODO: how exactly does this work again? Possibly need more entitlements for accessing the wifi information
//                Button(action: {
//                    // take to Trusted Networks View
//                }, label: {
//                    HStack {
//                        Text("Configure Trusted Networks")
//                        Image(systemName: "lock.shield")
//                    }
//                })
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }())
        .onAppear() { // MARK: This get called twice on startup?????
            if (connectedDevicesViewModel.devicesView == nil) {
                connectedDevicesViewModel.devicesView = self
            }
//            if (backgroundService._backgroundServiceDelegate == nil) {
//                backgroundService._backgroundServiceDelegate = connectedDevicesViewModel
//            }
            // MARK: If refreshDiscoveryAndList() is here, the device will go into "Remembered" for some reason and then immediately go back, but with an empty _plugins dictionary
            //refreshDiscoveryAndList()
            connectedDevicesViewModel.onDeviceListRefreshed()
            broadcastBatteryStatusAllDevices()
            //onDeviceListRefreshedInsideView(vm: connectedDevicesViewModel)
        }
    }
    
    func deleteDevice(at offsets: IndexSet) {
        if (offsets.first != nil) {
            print("Remembered device \(String(describing: ((backgroundService._devices[savedDevicesIds[offsets.first!]]) as! Device)._name)) removed at index \(offsets.first!)")
            backgroundService.unpairDevice(savedDevicesIds[offsets.first!])
            savedDevicesIds.remove(atOffsets: offsets)
        }
    }

    func onPairRequestInsideView(_ deviceId: String!) -> Void {
        currPairingDeviceId = deviceId
//        self.localNotificationService.sendNotification(title: "Incoming Pairing Request", subtitle: nil, body: "\(connectedDevicesViewModel.visibleDevices[currPairingDeviceId!] ?? "ERROR") wants to pair with this device", launchIn: 2)
        if (noCurrentlyActiveAlert()) {
            showingOnPairRequestAlert = true
        } else {
            AudioServicesPlaySystemSound(soundAudioToneBusy)
            print("Unable to display onPairRequest Alert, another alert already active")
        }
    }
    
    func onPairTimeoutInsideView(_ deviceId: String!) -> Void {
        //currPairingDeviceId = nil
        if(noCurrentlyActiveAlert()) {
            showingOnPairTimeoutAlert = true
        } else {
            AudioServicesPlaySystemSound(soundAudioToneBusy)
            print("Unable to display onPairTimeout Alert, another alert already active")
        }
    }
    
    func onPairSuccessInsideView(_ deviceId: String!) -> Void {
        if (noCurrentlyActiveAlert()) {
            showingOnPairSuccessAlert = true
        } else {
            AudioServicesPlaySystemSound(soundAudioToneBusy)
            print("Unable to display onPairSuccess Alert, another alert already active, but device list is still refreshed")
        }
        connectedDevicesViewModel.onDeviceListRefreshed()
    }
    
    func onPairRejectedInsideView(_ deviceId: String!) -> Void {
        if (noCurrentlyActiveAlert()) {
            showingOnPairRejectedAlert = true
        } else {
            AudioServicesPlaySystemSound(soundAudioToneBusy)
            print("Unable to display onPairRejected Alert, another alert already active")
        }
    }
    
    func showPingAlertInsideView() -> Void {
        if (noCurrentlyActiveAlert()) {
            hapticGenerators[Int(HapticStyle.rigid.rawValue)].impactOccurred(intensity: 0.8)
            AudioServicesPlaySystemSound(soundSMSReceived)
            showingPingAlert = true
        } else {
            AudioServicesPlaySystemSound(soundAudioToneBusy)
            print("Unable to display showingPingAlert Alert, another alert already active, but haptics and sounds are still played")
        }
    }
    
    func showFindMyPhoneAlertInsideView() -> Void {
        if (noCurrentlyActiveAlert()) {
            showingFindMyPhoneAlert = true
            while (showingFindMyPhoneAlert) {
                hapticGenerators[Int(HapticStyle.rigid.rawValue)].impactOccurred(intensity: 1.0)
//                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
//                    AudioServicesPlaySystemSound(soundCalendarAlert)
//                }
                AudioServicesPlaySystemSound(soundCalendarAlert)
                Thread.sleep(forTimeInterval: 4)
            }
        } else {
            AudioServicesPlaySystemSound(soundAudioToneBusy)
            print("Unable to display showFindMyPhoneAlert Alert, another alert already active, alert haptics and tone not played")
        }
    }
    
    func showFileReceivedAlertInsideView() -> Void {
//        if (noCurrentlyActiveAlert()) {
//            showingFileReceivedAlert = true
//        } else {
//            AudioServicesPlaySystemSound(soundAudioToneBusy)
//            print("Unable to display File Received Alert, another alert already active")
//        }
        AudioServicesPlaySystemSound(soundMailReceived)
    }
    
    private func noCurrentlyActiveAlert() -> Bool {
        return (!showingOnPairRequestAlert &&
                !showingOnPairTimeoutAlert &&
                !showingOnPairSuccessAlert &&
                !showingOnPairRejectedAlert &&
                !showingOnSelfPairOutgoingRequestAlert &&
                !showingOnSelectSavedDeviceAlert &&
                !showingPingAlert &&
                !showingFindMyPhoneAlert) //&& !showingFileReceivedAlert
    }
    
    func onDeviceListRefreshedInsideView(vm : ConnectedDevicesViewModel) -> Void {
        withAnimation {
            connectedDevicesIds = Array(vm.connectedDevices.keys)//.sort
            visibleDevicesIds = Array(vm.visibleDevices.keys)//.sort
            savedDevicesIds = Array(vm.savedDevices.keys)//.sort
        }
    }
    
    func refreshDiscoveryAndList() -> Void {
//        let group = DispatchGroup()
//        group.enter()
//        DispatchQueue.main.async {
//            backgroundService.refreshDiscovery()
//            group.leave()
//        }
////        DispatchQueue.main.async {
////            backgroundService.reloadAllPlugins()
////            group.leave()
////        }
//        DispatchQueue.main.async {
//            backgroundService.refreshVisibleDeviceList()
//            group.leave()
//        }
//        group.wait()
//        broadcastBatteryStatusAllDevices()
        backgroundService.refreshDiscovery()
        backgroundService.refreshVisibleDeviceList()
        //backgroundService.reloadAllPlugins()
        broadcastBatteryStatusAllDevices()
    }
    
}

//struct DevicesView_Previews: PreviewProvider {
//    static var previews: some View {
//        DevicesView()
//    }
//}
