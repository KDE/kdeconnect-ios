/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  DevicesDetailView.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-06-17.
//

import SwiftUI
import UniformTypeIdentifiers
import MediaPicker

struct DevicesDetailView: View {
    let detailsDeviceId: String
    @EnvironmentObject var alertManager: AlertManager

    @State private var showingPhotosPicker: Bool = false
    @State private var showingFilePicker: Bool = false
    @State private var showingPluginSettingsView: Bool = false
    
    @State var chosenFileURLs: [URL] = []
    @ObservedObject var viewModel = connectedDevicesViewModel
    private let logger = Logger(category: "DevicesDetailView")
    
    var isStillConnected: Bool {
        viewModel.connectedDevices.keys.contains(detailsDeviceId)
    }
    
    var body: some View {
        if isStillConnected {
            VStack {
                deviceActionsList
                
                NavigationLink(destination: DeviceDetailPluginSettingsView(detailsDeviceId: self.detailsDeviceId), isActive: $showingPluginSettingsView) {
                    EmptyView()
                }
            }
            .navigationTitle(backgroundService._devices[detailsDeviceId]!._name)
            .navigationBarItems(trailing:
                Menu {
                if ((backgroundService._devices[detailsDeviceId]!._pluginsEnableStatus[.ping] != nil) && backgroundService._devices[detailsDeviceId]!._pluginsEnableStatus[.ping] as! Bool) {
                        Button {
                            (backgroundService._devices[detailsDeviceId]!._plugins[.ping] as! Ping).sendPing()
                        } label: {
                            Label("Send Ping", systemImage: "megaphone")
                        }
                    }
                    
                if ((backgroundService._devices[detailsDeviceId]!._pluginsEnableStatus[.findMyPhoneRequest] != nil) && backgroundService._devices[detailsDeviceId]!._pluginsEnableStatus[.findMyPhoneRequest] as! Bool) {
                        Button {
                            (backgroundService._devices[detailsDeviceId]!._plugins[.findMyPhoneRequest] as! FindMyPhone).sendFindMyPhoneRequest()
                        } label: {
                            Label("Ring Device", systemImage: "bell")
                        }
                    }
                    
                    Button {
                        showingPluginSettingsView = true
                    } label: {
                        Label("Plugin Settings", systemImage: "dot.arrowtriangles.up.right.down.left.circle")
                    }
                    
                    Button {
                        alertManager.queueAlert(prioritize: true, title: "Encryption Info") {
                            Text("SHA256 fingerprint of your device certificate is:\n\((certificateService.hostCertificateSHA256HashFormattedString == nil) ? "ERROR" : certificateService.hostCertificateSHA256HashFormattedString!)\n\nSHA256 fingerprint of remote device certificate is: \n\((backgroundService._devices[detailsDeviceId]!._SHA256HashFormatted == nil || backgroundService._devices[detailsDeviceId]!._SHA256HashFormatted.isEmpty) ? "Unable to retrieve fingerprint of remote device. Add the remote device's IP address directly using Configure Devices By IP and Refresh Discovery" : backgroundService._devices[detailsDeviceId]!._SHA256HashFormatted)")
                        } buttons: {}
                    } label: {
                        Label("Encryption Info", systemImage: "lock.doc")
                    }
                    
                    Button {
                        alertManager.queueAlert(prioritize: true, title: "Unpair With Device?") {
                            Text("Unpair with \(backgroundService._devices[detailsDeviceId]!._name)?")
                        } buttons: {
                            Button("No, Stay Paired", role: .cancel) {}
                            Button("Yes, Unpair", role: .destructive) {
                                backgroundService.unpairDevice(detailsDeviceId)
                            }
                        }
                    } label: {
                        Label("Unpair", systemImage: "wifi.slash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            )
            .mediaImporter(isPresented: $showingPhotosPicker, allowedMediaTypes: .all, allowsMultipleSelection: true) { result in
                switch result {
                case .success(let chosenMediaURLs):
                    if chosenMediaURLs.isEmpty {
                        logger.info("Media Picker picked nothing")
                    } else {
                        DispatchQueue.main.async {
                            (backgroundService._devices[detailsDeviceId]!._plugins[.share] as! Share)
                                .prepAndInitFileSend(fileURLs: chosenMediaURLs)
                        }
                    }
                case .failure(let error):
                    logger.error("Media Picker Error: \(error.localizedDescription, privacy: .public)")
                }
            } loadingOverlay: { progress in
                NavigationView {
                    ProgressView(progress)
                        .padding()
                        .navigationTitle(Text("Preparing Media…"))
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .fileImporter(isPresented: $showingFilePicker, allowedContentTypes: allUTTypes, allowsMultipleSelection: true) { result in
                switch result {
                case .success(let chosenFileURLs):
                    if chosenFileURLs.isEmpty {
                        logger.info("Document Picker picked nothing")
                    } else {
                        (backgroundService._devices[detailsDeviceId]!._plugins[.share] as! Share).prepAndInitFileSend(fileURLs: chosenFileURLs)
                    }
                case .failure(let error):
                    logger.error("Document Picker Error: \(error.localizedDescription, privacy: .public)")
                }
            }
            .onAppear {
                // TODO: use if let as
                if ((backgroundService._devices[detailsDeviceId]!._pluginsEnableStatus[.runCommand] != nil) && backgroundService._devices[detailsDeviceId]!._pluginsEnableStatus[.runCommand] as! Bool) {
                    (backgroundService._devices[detailsDeviceId]!._plugins[.runCommand] as! RunCommand).requestCommandList()
                }
            }
        } else {
            VStack {
                Spacer()
                Image(systemName: "wifi.slash")
                    .foregroundColor(.red)
                    .font(.system(size: 40))
                Text("Device Offline")
                Spacer()
            }
        }
    }
    
    var deviceActionsList: some View {
        List {
            Section(header: Text("Actions")) {
                if ((backgroundService._devices[detailsDeviceId]!._pluginsEnableStatus[.clipboard] != nil) && backgroundService._devices[detailsDeviceId]!._pluginsEnableStatus[.clipboard] as! Bool) {
                    Button {
                        (backgroundService._devices[detailsDeviceId]!._plugins[.clipboard] as! Clipboard).sendClipboardContentOut()
                    } label: {
                        Label("Push Local Clipboard", systemImage: "square.and.arrow.up.on.square.fill")
                    }
                    .accentColor(.primary)
                }
                
                if ((backgroundService._devices[detailsDeviceId]!._pluginsEnableStatus[.share] != nil) && backgroundService._devices[detailsDeviceId]!._pluginsEnableStatus[.share] as! Bool) {
                    Button {
                        showingPhotosPicker = true
                    } label: {
                        Label("Send Photos and Videos", systemImage: "photo.on.rectangle")
                    }
                    .accentColor(.primary)
                    
                    Button {
                        showingFilePicker = true
                    } label: {
                        Label("Send Files", systemImage: "folder")
                    }
                    .accentColor(.primary)
                }
                
                if ((backgroundService._devices[detailsDeviceId]!._pluginsEnableStatus[.presenter] != nil) && backgroundService._devices[detailsDeviceId]!._pluginsEnableStatus[.presenter] as! Bool) {
                    NavigationLink(destination: PresenterView(detailsDeviceId: detailsDeviceId)) {
                        Label("Slideshow Remote", systemImage: "slider.horizontal.below.rectangle")
                    }
                    .accentColor(.primary)
                }
                
                if ((backgroundService._devices[detailsDeviceId]!._pluginsEnableStatus[.runCommand] != nil) && backgroundService._devices[detailsDeviceId]!._pluginsEnableStatus[.runCommand] as! Bool) {
                    NavigationLink(destination: RunCommandView(detailsDeviceId: self.detailsDeviceId)) {
                        Label("Run Command", systemImage: "terminal")
                    }
                    .accentColor(.primary)
                }
                
                if ((backgroundService._devices[detailsDeviceId]!._pluginsEnableStatus[.mousePadRequest] != nil) && backgroundService._devices[detailsDeviceId]!._pluginsEnableStatus[.mousePadRequest] as! Bool) {
                    NavigationLink(destination: RemoteInputView(detailsDeviceId: self.detailsDeviceId)) {
                        Label("Remote Input", systemImage: "hand.tap")
                    }
                    .accentColor(.primary)
                }
            }
            
            Section(header: Text("Device Status")) {
                BatteryStatus(device: backgroundService._devices[detailsDeviceId]!) { battery in
                    HStack {
                        Label {
                            Text("Battery Level")
                        } icon: {
                            Image(systemName: battery.statusSFSymbolName)
                                .foregroundColor(battery.statusColor ?? .primary)
                        }
                        Spacer()
                        Text("\(percent: battery.remoteChargeLevel)")
                    }
                }
            }
            
            if let device = backgroundService._devices[detailsDeviceId],
               device._pluginsEnableStatus[.share] as? Bool == true {
                FileTransferStatusSection(share: device._plugins[.share] as! Share)
            }
        }
        .environment(\.defaultMinListRowHeight, 50) // TODO: make this dynamic with GeometryReader???
    }
}

#if DEBUG
struct DevicesDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let detailsDeviceId = "MacBook"
        UIPreview.setupFakeDevices()
        
        return NavigationView {
            DevicesDetailView(detailsDeviceId: detailsDeviceId)
        }
        .environmentObject(AlertManager())
    }
}
#endif
