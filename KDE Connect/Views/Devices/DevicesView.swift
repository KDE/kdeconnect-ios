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

#if !os(macOS)

import SwiftUI
import Combine
import AVFoundation

struct DevicesView: View {
    @EnvironmentObject var alertManager: AlertManager
    @EnvironmentObject private var kdeConnectSettings: KdeConnectSettings

    var connectedDevicesIds: [String] {
        viewModel.connectedDevices.keys.sorted()
    }
    var visibleDevicesIds: [String] {
        viewModel.visibleDevices.keys.sorted()
    }
    var savedDevicesIds: [String] {
        viewModel.savedDevices.keys.sorted()
    }
    
    @State private var showingConfigureDevicesByIPView: Bool = false
    // The selected device is kept outside of the list rows, so that the details view
    // stays open when the device disconnects temporarily (e.g. when the app goes to the
    // background, which closes all the links) and its row disappears from the list.
    @State private var selectedDeviceId: String?
    @State private var showingDeviceDetailView: Bool = false
    @State private var isDeviceDiscoveryHelpPresented = false
        
    @ObservedObject var viewModel: ConnectedDevicesViewModel = connectedDevicesViewModel
    @State private var findMyPhoneTimer = Empty<Date, Never>().eraseToAnyPublisher()

    // @ObservedObject var localNotificationService = LocalNotificationService()
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    private let logger = Logger()
    
    var body: some View {
        VStack {
            devicesList
                .refreshable {
                    refreshDiscovery()
                }
                .sheet(isPresented: $isDeviceDiscoveryHelpPresented) {
                    DeviceDiscoveryHelp()
                }
            
            NavigationLink(destination: ConfigureDeviceByIPView(), isActive: $showingConfigureDevicesByIPView) {
                EmptyView()
            }

            NavigationLink(isActive: $showingDeviceDetailView) {
                if let selectedDeviceId {
                    DevicesDetailView(detailsDeviceId: selectedDeviceId)
                        .id(selectedDeviceId)
                }
            } label: {
                EmptyView()
            }
        }
        .onChange(of: viewModel.connectedDevices) { _ in
            closeDeviceDetailViewIfDeviceIsGone()
        }
        .onChange(of: viewModel.savedDevices) { _ in
            closeDeviceDetailViewIfDeviceIsGone()
        }
        .navigationTitle("Devices")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: refreshDiscovery) {
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
            }
        }
        .safeAreaInset(edge: .bottom, alignment: .center, spacing: 0) {
            discoveryHelpButton
                .padding(.bottom, 8)
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
            updateFindMyPhoneTimer(isRunning: true)
        }
        .onReceive(findMyPhoneTimer) { _ in
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 1.0)
            SystemSound.calendarAlert.play()
        }
    }
    
    var connectedDevicesSection: some View {
        Section {
            if connectedDevicesIds.isEmpty {
                Text("No currently connected devices.")
                    .padding(.vertical, 8)
            } else {
                ForEach(connectedDevicesIds, id: \.self) { key in
                    Button {
                        selectedDeviceId = key
                        showingDeviceDetailView = true
                    } label: {
                        HStack {
                            Image(systemName: "wifi")
                                .foregroundColor(.green)
                                .font(.title2)
                            VStack(alignment: .leading) {
                                HStack {
                                    // FIXME: replace ??? with proper error message
                                    Text(viewModel.connectedDevices[key] ?? "???")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    if let device = backgroundService._devices[key] {
                                        Image(systemName: device._deviceInfo.type.sfSymbolName)
                                            .font(.title3)
                                    }
                                }
                                BatteryStatus(device: backgroundService._devices[key]!) { battery in
                                    HStack {
                                        Image(systemName: battery.statusSFSymbolName)
                                            .font(.footnote)
                                            // FIXME: wrong foreground color
                                            .foregroundColor(battery.statusColor)
                                        Text("\(percent: battery.remoteChargeLevel)")
                                            .font(.footnote)
                                    }
                                }
                                // TODO: Might want to add the device description as
                                // id:desc dictionary?
                                // Text(key)
                            }
                            Spacer()
                            Image(systemName: "chevron.forward")
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                        }
                        .foregroundColor(.primary)
                        .contentShape(Rectangle())
                    }
                    .listRowBackground(isShowingDetails(ofDeviceWithId: key) ? Color(UIColor.systemFill) : nil)
                }
            }
        } header: {
            Text("Connected Devices")
        } footer: {
            if !savedDevicesIds.isEmpty {
                Text("If a remembered device is already online but not shown here, try Refresh Discovery.")
            }
        }
    }
    
    var discoverableDevicesSection: some View {
        Section {
            if visibleDevicesIds.isEmpty {
                Text("No additional devices are discovered on this network.")
                    .padding(.vertical, 8)
            } else {
                ForEach(visibleDevicesIds, id: \.self) { key in
                    Button {
                        alertManager.queueAlert(prioritize: true, title: "Initiate Pairing?") {
                            currentPairingDeviceName(id: key).map {
                                Text("Request to pair with '\($0)'")
                            }
                        } buttons: {
                            Button("Cancel", role: .cancel) {}
                            Button("Pair") {
                                backgroundService.pairDevice(key)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "badge.plus.radiowaves.right")
                                .foregroundColor(.blue)
                                .font(.title2)
                            VStack(alignment: .leading) {
                                HStack {
                                    // FIXME: replace ??? with proper error message
                                    Text(viewModel.visibleDevices[key] ?? "???")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    if let device = backgroundService._devices[key] {
                                        Image(systemName: device._deviceInfo.type.sfSymbolName)
                                            .font(.title3)
                                            .foregroundColor(.primary)
                                    }
                                }
                                let device = backgroundService._devices[key]
                                if (device?._pairStatus == PairStatus.Requested) {
                                    Text("Verification key: \(CertificateService.shared.getVerificationKey(deviceId: key))")
                                        .font(.subheadline)
                                } else {
                                    Text("Tap to start pairing")
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                }
            }
        } header: {
            Text("Discovered Devices")
        }
    }
    
    private var discoveryHelpButton: some View {
        let button = Button {
            isDeviceDiscoveryHelpPresented = true
        } label: {
            Text("Can't find your devices here?")
                .foregroundColor(.accentColor)
        }
        return Group {
            if #available(iOS 26.0, *) {
                button
                    .buttonStyle(.glass)
            } else {
                button
                    .padding(8)
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(Capsule())
            }
        }
    }
    
    var rememberedDevicesSection: some View {
        Section {
            if savedDevicesIds.isEmpty {
                Text("Previously connected devices will appear here.")
                    .padding(.vertical, 8)
            } else {
                ForEach(savedDevicesIds, id: \.self) { key in
                    Button {
                        // currPairingDeviceId = key
                        // showingOnSelectSavedDeviceAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "wifi.slash")
                                .foregroundColor(.red)
                                .font(.title2)
                            VStack(alignment: .leading) {
                                HStack {
                                    // FIXME: replace ??? with proper error message
                                    Text(viewModel.savedDevices[key] ?? "???")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    if let device = backgroundService._devices[key] {
                                        Image(systemName: device._deviceInfo.type.sfSymbolName)
                                            .font(.title3)
                                    }
                                }
                                // TODO: Might want to add the device description as
                                // id:desc dictionary?
                                // Text(key)
                            }
                        }
                    }
                    .disabled(true)
                }
                .onDelete(perform: deleteDevice)
            }
        } header: {
            Text("Remembered Devices")
        } footer: {
            if !savedDevicesIds.isEmpty {
                Text("To connect to remembered devices, make sure they are connected to the same network as this device.")
            }
        }
    }
    
    private func isShowingDetails(ofDeviceWithId deviceId: String) -> Bool {
        // In compact width the details view covers the list, so only highlight in split view
        horizontalSizeClass == .regular && showingDeviceDetailView && selectedDeviceId == deviceId
    }

    /// Keeps the details view open while the selected device is temporarily disconnected
    /// (it moves to the remembered devices), but closes it if the device was unpaired.
    private func closeDeviceDetailViewIfDeviceIsGone() {
        guard showingDeviceDetailView, let selectedDeviceId else { return }
        if viewModel.connectedDevices[selectedDeviceId] == nil
            && viewModel.savedDevices[selectedDeviceId] == nil {
            showingDeviceDetailView = false
        }
    }

    func currentPairingDeviceName(id: String) -> String? {
        backgroundService._devices[id]?._deviceInfo.name
    }

    func deleteDevice(at offsets: IndexSet) {
        offsets
            .map { (offset: $0, id: savedDevicesIds[$0]) }
            .forEach { device in
                // TODO: Update Device.m to indicate nullability
                let name = backgroundService._devices[device.id]!._deviceInfo.name
                logger.info("Remembered device \(name, privacy: .private(mask: .hash)) removed at index \(device.offset)")
                backgroundService.unpairDevice(device.id)
            }
    }
    
    func onPairRequest(fromDeviceWithID deviceId: String!) {
//        self.localNotificationService.sendNotification(title: "Incoming Pairing Request", subtitle: nil, body: "\(viewModel.visibleDevices[currPairingDeviceId!] ?? "ERROR") wants to pair with this device", launchIn: 2)
        alertManager.queueAlert(title: "Incoming Pairing Request") {
            currentPairingDeviceName(id: deviceId).map {
                Text("Pair request from '\($0)'\nVerification key: \(CertificateService.shared.getVerificationKey(deviceId: deviceId))")
            }
        } buttons: {
            Button("Do Not Pair", role: .cancel) {
                backgroundService.unpairDevice(deviceId)
            }
            Button("Pair") {
                backgroundService.pairDevice(deviceId)
            }
        }
    }
    
    func onPairTimeout(toDeviceWithID deviceId: String!) {
        alertManager.queueAlert(title: "Pairing Timed Out") {
            currentPairingDeviceName(id: deviceId).map {
                Text("Pairing with '\($0)' failed")
            }
        } buttons: {
            Button("OK", role: .cancel) {}
        }
    }
    
    func onPairSuccess(withDeviceWithID deviceId: String!) {
        alertManager.queueAlert(title: "Pairing Complete") {
            currentPairingDeviceName(id: deviceId).map {
                Text("Pairing with '\($0)' succeeded")
            }
        } buttons: {
            Button("Nice", role: .cancel) {}
        }
    }
    
    func onPairRejected(byDeviceWithID deviceId: String!) {
        alertManager.queueAlert(title: "Pairing Rejected") {
            currentPairingDeviceName(id: deviceId).map {
                Text("Pairing with '\($0)' failed")
            }
        } buttons: {
            Button("OK", role: .cancel) {}
        }
    }
    
    func showPingAlert() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.8)
        SystemSound.smsReceived.play()
        alertManager.queueAlert(title: "Ping!") {
            Text("Ping received from a connected device.")
        }
    }
    
    func showFindMyPhoneAlert() {
        alertManager.queueAlert(prioritize: true, title: "Find My Phone Mode") {
            Text("Find My Phone initiated from a remote device")
        } buttons: {
            Button("I FOUND IT!", role: .cancel) {
                updateFindMyPhoneTimer(isRunning: false)
            }
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
    
    func refreshDiscovery() {
        backgroundService.refreshDiscovery()
    }
}

struct DevicesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DevicesView()
                .listStyle(.sidebar)
                .environmentObject(KdeConnectSettings.shared)
        }
    }
}

#endif
