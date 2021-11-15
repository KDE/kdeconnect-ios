/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  DevicesView.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-06-17.
//

import SwiftUI
import AVFoundation

struct DevicesView: View {
    var connectedDevicesIds: [String] {
        viewModel.connectedDevices.keys.sorted()
    }
    var visibleDevicesIds: [String] {
        viewModel.visibleDevices.keys.sorted()
    }
    var savedDevicesIds: [String] {
        viewModel.savedDevices.keys.sorted()
    }
    
    @State var currPairingDeviceId: String?
    @State private var showingOnPairRequestAlert: Bool = false
    @State private var showingOnPairTimeoutAlert: Bool = false
    @State private var showingOnPairSuccessAlert: Bool = false
    @State private var showingOnPairRejectedAlert: Bool = false
    @State private var showingOnSelfPairOutgoingRequestAlert: Bool = false
    @State private var showingPingAlert: Bool = false
    @State private var showingFindMyPhoneAlert: Bool = false
    @State private var showingFileReceivedAlert: Bool = false
    
    @State private var showingConfigureDevicesByIPView: Bool = false
    
    @State var viewUpdate: Bool = false
    
    @ObservedObject var viewModel: ConnectedDevicesViewModel = connectedDevicesViewModel
    
    //@ObservedObject var localNotificationService = LocalNotificationService()
    
    var body: some View {
        VStack {
        if #available(iOS 15.0, *) {
            devicesList
                .refreshable() {
                    refreshDiscoveryAndList()
                }
                .alert("Incoming Pairing Request", isPresented: $showingOnPairRequestAlert) { // TODO: Might want to add a "pairing in progress" UI element?
                    Button("Do Not Pair", role: .cancel) {}
                    Button("Pair") {
                        backgroundService.pairDevice(currPairingDeviceId)
                    }
                } message: {
                    wantsToPairMessage
                }
                .alert("Pairing Complete", isPresented: $showingOnPairSuccessAlert) {
                    Button("Nice", role: .cancel) {
                        currPairingDeviceId = nil
                    }
                } message: {
                    paringCompleteMessage
                }
                .alert("Initiate Pairing?", isPresented: $showingOnSelfPairOutgoingRequestAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Pair") {
                        backgroundService.pairDevice(currPairingDeviceId)
                    }
                } message: {
                    initiatePairingMessage
                }
                .alert("Pairing Timed Out", isPresented: $showingOnPairTimeoutAlert) {
                    Button("OK", role: .cancel) {
                        currPairingDeviceId = nil
                    }
                } message: {
                    pairingTimeoutMessage
                }
                .alert("Pairing Rejected", isPresented: $showingOnPairRejectedAlert) {
                    Button("OK", role: .cancel) {
                        currPairingDeviceId = nil
                    }
                } message: {
                    pairingRejectedMessage
                }
                .alert("Ping!", isPresented: $showingPingAlert) {} message: {
                    Text("Ping received from a connected device.")
                }
                .alert("Find My Phone Mode", isPresented: $showingFindMyPhoneAlert) {
                    Button("I FOUND IT!", role: .cancel) {}
                } message: {
                    Text("Find My Phone initiated from a remote device")
                }
        } else {
            // Fallback on earlier versions, use Alert component
            devicesList
            
            iOS14CompatibilityAlert(
                description: Text("iOS14 Incoming pairing Alert \(currPairingDeviceId ?? "")"),
                isPresented: $showingOnPairRequestAlert) {
                    Alert(
                        title: Text("Incoming Pairing Request"),
                        message: wantsToPairMessage,
                        primaryButton: .default(Text("Pair"), action: {
                            backgroundService.pairDevice(currPairingDeviceId)
                        }),
                        secondaryButton: .cancel(Text("Cancel"), action: {})
                    )
                }
            
            iOS14CompatibilityAlert(
                description: Text("iOS14 Pair complete Alert \(currPairingDeviceId ?? "")"),
                isPresented: $showingOnPairSuccessAlert) {
                    Alert(
                        title: Text("Pairing Complete"),
                        message: paringCompleteMessage,
                        dismissButton: .cancel(Text("Nice"), action: { currPairingDeviceId = nil })
                    )
                }
            
            iOS14CompatibilityAlert(
                description: Text("iOS14 Initiate pairing Alert for \(currPairingDeviceId ?? "")"),
                isPresented: $showingOnSelfPairOutgoingRequestAlert) {
                    Alert(
                        title: Text("Initiate Pairing?"),
                        message: initiatePairingMessage,
                        primaryButton: .default(Text("Pair"), action: {
                            backgroundService.pairDevice(currPairingDeviceId)
                        }),
                        secondaryButton: .cancel(Text("Cancel"), action: {})
                    )
                }
            
            iOS14CompatibilityAlert(
                description: Text("iOS14 Pair timeout Alert \(currPairingDeviceId ?? "")"),
                isPresented: $showingOnPairTimeoutAlert) {
                    Alert(
                        title: Text("Pairing Timed Out"),
                        message: pairingTimeoutMessage,
                        dismissButton: .cancel(Text("OK"), action: { currPairingDeviceId = nil })
                    )
                }
            
            iOS14CompatibilityAlert(
                description: Text("iOS14 Pair rejection Alert \(currPairingDeviceId ?? "")"),
                isPresented: $showingOnPairRejectedAlert) {
                    Alert(
                        title: Text("Pairing Rejected"),
                        message: pairingRejectedMessage,
                        dismissButton: .cancel(Text("OK"), action: { currPairingDeviceId = nil })
                    )
                }
            
            iOS14CompatibilityAlert(
                description: Text("iOS14 Ping Alert"),
                isPresented: $showingPingAlert) {
                    Alert(
                        title: Text("Ping!"),
                        message: Text("Ping received from a connected device.")
                    )
                }
            
            iOS14CompatibilityAlert(
                description: Text("iOS14 Find my phone Alert"),
                isPresented: $showingFindMyPhoneAlert) {
                    Alert(
                        title: Text("Find My Phone Mode"),
                        message: Text("Find My Phone initiated from a remote device"),
                        dismissButton: .cancel(Text("I FOUND IT!"), action: { })
                    )
                }
            
            // TODO: refreshable(pull to refresh) for early version
        }
            
            NavigationLink(destination: ConfigureDeviceByIPView(), isActive: $showingConfigureDevicesByIPView) {
                EmptyView()
            }
            // This is an invisible view using changes in viewUpdate to force SwiftUI to re-render the entire screen. We want this because the battery information is NOT a @State variables, as such in order for updates to actually register, we need to force the view to re-render
            Text(viewUpdate ? "True" : "False")
                .frame(width: 0, height: 0)
                .opacity(0)
                .accessibilityHidden(true)
        }
        .navigationTitle("Devices")
        .navigationBarItems(trailing:
            Menu {
                Button(action: refreshDiscoveryAndList) {
                    Label("Refresh Discovery", systemImage: "arrow.triangle.2.circlepath")
                }
            
                Button {
                    showingConfigureDevicesByIPView = true
                } label: {
                    Label("Configure Devices By IP", systemImage: "network")
                }
                
                // TODO: Implement trusted networks, possibly need entitlement to access LAN information
                // Label("Configure Trusted Networks", systemName: "lock.shield")
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        )
        .onAppear {
            // TODO: Don't hold the view in the viewModel!!!
            if (viewModel.devicesView == nil) {
                viewModel.devicesView = self
            }
            viewModel.onDeviceListRefreshed()
            broadcastBatteryStatusAllDevices()
        }
    }
    
    var devicesList: some View {
        List {
            connectedDevicesSection
            
            discoverableDevicesSection
            
            rememberedDevicesSection
        }
        .environment(\.defaultMinListRowHeight, 60) // TODO: make this dynamic with GeometryReader???
    }
    
    var connectedDevicesSection: some View {
        Section(header: Text("Connected Devices")) {
            if (connectedDevicesIds.isEmpty) {
                Text("No devices are currently connected.\nConnected devices will appear here. Please Refresh Discovery if a saved device is already online but not shown here.")
                    .padding(.vertical, 8)
            } else {
                ForEach(connectedDevicesIds, id: \.self) { key in
                    NavigationLink(
                        // How do we know what to pass to the details view?
                        // Use the "key" from ForEach aka device ID to get it from
                        // backgroundService's _devices dictionary for the value (Device class objects)
                        destination: DevicesDetailView(detailsDeviceId: key)
                    ) {
                        HStack {
                            Image(systemName: "wifi")
                                .foregroundColor(.green)
                                .font(.title2)
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(viewModel.connectedDevices[key] ?? "???")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    if let device = backgroundService._devices[key] {
                                        Image(systemName: device._type.sfSymbolName)
                                            .font(.title3)
                                    }
                                }
                                if ((backgroundService._devices[key]!._pluginsEnableStatus[PACKAGE_TYPE_BATTERY_REQUEST] == nil) || ((backgroundService._devices[key]!._plugins[PACKAGE_TYPE_BATTERY_REQUEST] as! Battery).remoteChargeLevel == 0)) {
                                    Text("No battery detected in device")
                                        .font(.footnote)
                                } else if (!(backgroundService._devices[key]!._pluginsEnableStatus[PACKAGE_TYPE_BATTERY_REQUEST] as! Bool)) {
                                    Text("Battery Plugin Disabled")
                                        .font(.footnote)
                                } else {
                                    HStack {
                                        Image(systemName: (backgroundService._devices[key]!._plugins[PACKAGE_TYPE_BATTERY_REQUEST] as! Battery).getSFSymbolNameFromBatteryStatus())
                                            .font(.footnote)
                                            .foregroundColor((backgroundService._devices[key]!._plugins[PACKAGE_TYPE_BATTERY_REQUEST] as! Battery).getSFSymbolColorFromBatteryStatus())
                                        Text("\((backgroundService._devices[key]!._plugins[PACKAGE_TYPE_BATTERY_REQUEST] as! Battery).remoteChargeLevel)%")
                                            .font(.footnote)
                                    }
                                }
                                // TODO: Might want to add the device description as
                                // id:desc dictionary?
                                //Text(key)
                            }
                        }
                    }
                }
            }
        }
    }
    
    var discoverableDevicesSection: some View {
        Section(header: Text("Discovered Devices"), footer: Text("If the network is shared/public it likely has broadcasting disabled, please manually add the devices in the \"Configure Devices By IP\" menu from the 3-dots drop-down button.")) {
            if (visibleDevicesIds.isEmpty) {
                Text("No devices are discovered on this network.\nMake sure to Refresh Discovery and check that the other devices are also running KDE Connect & are connected to the same network as this device.")
                    .padding(.vertical, 8)
            } else {
                ForEach(visibleDevicesIds, id: \.self) { key in
                    Button {
                        currPairingDeviceId = key
                        showingOnSelfPairOutgoingRequestAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "badge.plus.radiowaves.right")
                                .foregroundColor(.blue)
                                .font(.title2)
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(viewModel.visibleDevices[key] ?? "???")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    if let device = backgroundService._devices[key] {
                                        Image(systemName: device._type.sfSymbolName)
                                            .font(.title3)
                                            .foregroundColor(.black)
                                    }
                                }
                                Text("Tap to start pairing")
                                    .font(.subheadline)
                            }
                        }
                    }
                }
            }
        }
    }
    
    var rememberedDevicesSection: some View {
        Section(header: Text("Remembered Devices"), footer: Text("To connect to Remembered Devices, make sure they are connected to the same network as this device.")) {
            if (savedDevicesIds.isEmpty) {
                Text("No remembered devices.\nDevices that were previously connected will appear here.")
                    .padding(.vertical, 8)
            } else {
                ForEach(savedDevicesIds, id: \.self) { key in
                    Button {
                        //currPairingDeviceId = key
                        //showingOnSelectSavedDeviceAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "wifi.slash")
                                .foregroundColor(.red)
                                .font(.title2)
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(viewModel.savedDevices[key] ?? "???")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    Image(systemName: backgroundService._devices[key]!._type.sfSymbolName)
                                        .font(.title3)
                                }
                                // TODO: Might want to add the device description as
                                // id:desc dictionary?
                                //Text(key)
                            }
                        }
                    }
                    .disabled(true)
                }
                .onDelete(perform: deleteDevice)
            }
        }
    }
    
    // MARK: - Alert Messages
    
    var wantsToPairMessage: Text? {
        currentPairingDeviceName.map {
            Text("\($0) wants to pair with this device")
        }
    }
    
    var paringCompleteMessage: Text? {
        currentPairingDeviceName.map {
            Text("Pairing with \($0) succeeded")
        }
    }
    
    var initiatePairingMessage: Text? {
        currentPairingDeviceName.map {
            Text("Request to pair with \($0)?")
        }
    }
    
    var pairingTimeoutMessage: Text? {
        currentPairingDeviceName.map {
            Text("Pairing with \($0) failed")
        }
    }
    
    var pairingRejectedMessage: Text? {
        currentPairingDeviceName.map {
            Text("Pairing with \($0) failed")
        }
    }
    
    var currentPairingDeviceName: String? {
        if let currPairingDeviceId = currPairingDeviceId {
            if let device = backgroundService._devices[currPairingDeviceId] {
                return device._name
            } else {
                print("Missing device for \(currPairingDeviceId)")
            }
        } else {
            print("Missing currPairingDeviceId")
        }
        return nil
    }
    
    func deleteDevice(at offsets: IndexSet) {
        for offset in offsets {
            // TODO: Update Device.m to indicate nullability
            let name = backgroundService._devices[savedDevicesIds[offset]]!._name!
            print("Remembered device \(name) removed at index \(offset)")
            backgroundService.unpairDevice(savedDevicesIds[offset])
        }
//        savedDevicesIds.remove(atOffsets: offsets)
    }
    
    func onPairRequestInsideView(_ deviceId: String!) -> Void {
        currPairingDeviceId = deviceId
//        self.localNotificationService.sendNotification(title: "Incoming Pairing Request", subtitle: nil, body: "\(viewModel.visibleDevices[currPairingDeviceId!] ?? "ERROR") wants to pair with this device", launchIn: 2)
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
        viewModel.onDeviceListRefreshed()
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
                !showingPingAlert &&
                !showingFindMyPhoneAlert) //&& !showingFileReceivedAlert
    }
    
//    func onDeviceListRefreshedInsideView(vm : ConnectedDevicesViewModel) -> Void {
//        withAnimation {
//            connectedDevicesIds = Array(vm.connectedDevices.keys)//.sort
//            visibleDevicesIds = Array(vm.visibleDevices.keys)//.sort
//            savedDevicesIds = Array(vm.savedDevices.keys)//.sort
//        }
//    }
    
    func refreshDiscoveryAndList() {
        withAnimation {
            backgroundService.refreshDiscovery()
            backgroundService.refreshVisibleDeviceList()
            broadcastBatteryStatusAllDevices()
        }
    }
}

//struct DevicesView_Previews: PreviewProvider {
//    static var previews: some View {
//        DevicesView()
//    }
//}
