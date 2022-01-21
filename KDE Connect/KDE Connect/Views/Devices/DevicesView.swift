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
import Combine
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
        
    @ObservedObject var viewModel: ConnectedDevicesViewModel = connectedDevicesViewModel
    @State private var findMyPhoneTimer = Empty<Date, Never>().eraseToAnyPublisher()

    //@ObservedObject var localNotificationService = LocalNotificationService()
    
    var body: some View {
        VStack {
            devicesList
                .refreshable {
                    refreshDiscoveryAndList()
                }
                .alert("Incoming Pairing Request", isPresented: $showingOnPairRequestAlert) { // TODO: Might want to add a "pairing in progress" UI element?
                    Button("Do Not Pair", role: .cancel) {}
                    Button("Pair") {
                        backgroundService.pairDevice(currPairingDeviceId)
                    }
                } message: {
                    currentPairingDeviceName.map {
                        Text("\($0) wants to pair with this device")
                    }
                }
                .alert("Pairing Complete", isPresented: $showingOnPairSuccessAlert) {
                    Button("Nice", role: .cancel) {
                        currPairingDeviceId = nil
                    }
                } message: {
                    currentPairingDeviceName.map {
                        Text("Pairing with \($0) succeeded")
                    }
                }
                .alert("Initiate Pairing?", isPresented: $showingOnSelfPairOutgoingRequestAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Pair") {
                        backgroundService.pairDevice(currPairingDeviceId)
                    }
                } message: {
                    currentPairingDeviceName.map {
                        Text("Request to pair with \($0)?")
                    }
                }
                .alert("Pairing Timed Out", isPresented: $showingOnPairTimeoutAlert) {
                    Button("OK", role: .cancel) {
                        currPairingDeviceId = nil
                    }
                } message: {
                    currentPairingDeviceName.map {
                        Text("Pairing with \($0) failed")
                    }
                }
                .alert("Pairing Rejected", isPresented: $showingOnPairRejectedAlert) {
                    Button("OK", role: .cancel) {
                        currPairingDeviceId = nil
                    }
                } message: {
                    currentPairingDeviceName.map {
                        Text("Pairing with \($0) failed")
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
        .onReceive(NotificationCenter.default.publisher(for: .didReceivePairRequestNotification, object: nil)
                    .receive(on: RunLoop.main)) { notification in
            onPairRequest(fromDeviceWithID: notification.userInfo?["deviceID"] as? String)
        }
        .onReceive(NotificationCenter.default.publisher(for: .pairRequestTimedOutNotification, object: nil)
                    .receive(on: RunLoop.main)) { notification in
            onPairTimeout(toDeviceWithID: notification.userInfo?["deviceID"] as? String)
        }
        .onReceive(NotificationCenter.default.publisher(for: .pairRequestSucceedNotification, object: nil)
                    .receive(on: RunLoop.main)) { notification in
            onPairSuccess(withDeviceWithID: notification.userInfo?["deviceID"] as? String)
        }
        .onReceive(NotificationCenter.default.publisher(for: .pairRequestRejectedNotification, object: nil)
                    .receive(on: RunLoop.main)) { notification in
            onPairRejected(byDeviceWithID: notification.userInfo?["deviceID"] as? String)
        }
        .onReceive(NotificationCenter.default.publisher(for: .didReceivePingNotification, object: nil)
                    .receive(on: RunLoop.main)) { _ in
            showPingAlert()
        }
        .onReceive(NotificationCenter.default.publisher(for: .didReceiveFindMyPhoneRequestNotification, object: nil)
                    .receive(on: RunLoop.main)) { _ in
            showFindMyPhoneAlert()
        }
        .onChange(of: showingFindMyPhoneAlert, perform: updateFindMyPhoneTimer)
        .onReceive(findMyPhoneTimer) { _ in
            hapticGenerators[Int(HapticStyle.rigid.rawValue)].impactOccurred(intensity: 1.0)
            AudioServicesPlaySystemSound(soundCalendarAlert)
        }
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
                                BatteryStatus(device: backgroundService._devices[key]!) { battery in
                                    HStack {
                                        Image(systemName: battery.statusSFSymbolName)
                                            .font(.footnote)
                                            .foregroundColor(battery.statusColor)
                                        Text("\(percent: battery.remoteChargeLevel)")
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
                                            .foregroundColor(.primary)
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
    
    var currentPairingDeviceName: String? {
        if let currPairingDeviceId = currPairingDeviceId {
            if let device = backgroundService._devices[currPairingDeviceId] {
                return device._name
            } else {
                print("Missing device for \(currPairingDeviceId)")
            }
        }
        // alerts evaluates eagerly, making currPairingDeviceId nil normally
        return nil
    }
    
    func deleteDevice(at offsets: IndexSet) {
        offsets
            .map { (offset: $0, id: savedDevicesIds[$0]) }
            .forEach { device in
                // TODO: Update Device.m to indicate nullability
                let name = backgroundService._devices[device.id]!._name!
                print("Remembered device \(name) removed at index \(device.offset)")
                backgroundService.unpairDevice(device.id)
            }
    }
    
    func onPairRequest(fromDeviceWithID deviceId: String!) {
        currPairingDeviceId = deviceId
//        self.localNotificationService.sendNotification(title: "Incoming Pairing Request", subtitle: nil, body: "\(viewModel.visibleDevices[currPairingDeviceId!] ?? "ERROR") wants to pair with this device", launchIn: 2)
        if (noCurrentlyActiveAlert()) {
            showingOnPairRequestAlert = true
        } else {
            AudioServicesPlaySystemSound(soundAudioToneBusy)
            print("Unable to display onPairRequest Alert, another alert already active")
        }
    }
    
    func onPairTimeout(toDeviceWithID deviceId: String!) {
        //currPairingDeviceId = nil
        if(noCurrentlyActiveAlert()) {
            showingOnPairTimeoutAlert = true
        } else {
            AudioServicesPlaySystemSound(soundAudioToneBusy)
            print("Unable to display onPairTimeout Alert, another alert already active")
        }
    }
    
    func onPairSuccess(withDeviceWithID deviceId: String!) {
        if (noCurrentlyActiveAlert()) {
            showingOnPairSuccessAlert = true
        } else {
            AudioServicesPlaySystemSound(soundAudioToneBusy)
            print("Unable to display onPairSuccess Alert, another alert already active, but device list is still refreshed")
        }
    }
    
    func onPairRejected(byDeviceWithID deviceId: String!) {
        if (noCurrentlyActiveAlert()) {
            showingOnPairRejectedAlert = true
        } else {
            AudioServicesPlaySystemSound(soundAudioToneBusy)
            print("Unable to display onPairRejected Alert, another alert already active")
        }
    }
    
    func showPingAlert() {
        if (noCurrentlyActiveAlert()) {
            hapticGenerators[Int(HapticStyle.rigid.rawValue)].impactOccurred(intensity: 0.8)
            AudioServicesPlaySystemSound(soundSMSReceived)
            showingPingAlert = true
        } else {
            AudioServicesPlaySystemSound(soundAudioToneBusy)
            print("Unable to display showingPingAlert Alert, another alert already active, but haptics and sounds are still played")
        }
    }
    
    func showFindMyPhoneAlert() {
        if (noCurrentlyActiveAlert()) {
            showingFindMyPhoneAlert = true
        } else {
            AudioServicesPlaySystemSound(soundAudioToneBusy)
            print("Unable to display showFindMyPhoneAlert Alert, another alert already active, alert haptics and tone not played")
        }
    }
    
    private func updateFindMyPhoneTimer(isRunning: Bool) {
        if isRunning {
            findMyPhoneTimer = Deferred {
                Just(Date())
            }
            .append(Timer.publish(every: 4, on: .main, in: .common).autoconnect())
            .eraseToAnyPublisher()
        } else {
            findMyPhoneTimer = Empty<Date, Never>().eraseToAnyPublisher()
        }
    }

    // TODO: maybe queue the alerts
    private func noCurrentlyActiveAlert() -> Bool {
        return (!showingOnPairRequestAlert &&
                !showingOnPairTimeoutAlert &&
                !showingOnPairSuccessAlert &&
                !showingOnPairRejectedAlert &&
                !showingOnSelfPairOutgoingRequestAlert &&
                !showingPingAlert &&
                !showingFindMyPhoneAlert) //&& !showingFileReceivedAlert
    }
    
    func refreshDiscoveryAndList() {
        withAnimation {
            backgroundService.refreshDiscovery()
            backgroundService.refreshVisibleDeviceList()
            broadcastBatteryStatusAllDevices()
        }
    }
}

struct DevicesView_Previews: PreviewProvider {
    static var previews: some View {
        DevicesView()
    }
}
