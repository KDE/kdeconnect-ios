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

#if !os(macOS)

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
        if isStillConnected, let device = backgroundService._devices[detailsDeviceId] {
            VStack {
                deviceActionsList(device: device)
                
                NavigationLink(destination: DeviceDetailPluginSettingsView(detailsDeviceId: self.detailsDeviceId), isActive: $showingPluginSettingsView) {
                    EmptyView()
                }
            }
            .navigationTitle(device._deviceInfo.name)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if device._pluginsEnableStatus[.ping] as? Bool == true {
                            Button {
                                (device._plugins[.ping] as? Ping)?.sendPing()
                            } label: {
                                Label("Send Ping", systemImage: "megaphone")
                            }
                        }
                        
                        if device._pluginsEnableStatus[.findMyPhoneRequest] as? Bool == true {
                            Button {
                                (device._plugins[.findMyPhoneRequest] as? FindMyPhone)?.sendFindMyPhoneRequest()
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
                                Text("SHA256 fingerprint of your device certificate is:\n\(CertificateService.shared.getHostCertificateSHA256HashFormattedString())\n\nSHA256 fingerprint of remote device certificate is: \n\(CertificateService.shared.getRemoteCertificateSHA256HashFormattedString(deviceId: detailsDeviceId))")
                            }
                        } label: {
                            Label("Encryption Info", systemImage: "lock.doc")
                        }
                        
                        Button {
                            let deviceName = device._deviceInfo.name
                            alertManager.queueAlert(prioritize: true, title: "Unpair With Device?") {
                                Text("Unpair with \(deviceName)?")
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
                }
            }
            .mediaImporter(isPresented: $showingPhotosPicker, allowedMediaTypes: .all, allowsMultipleSelection: true) { result in
                switch result {
                case .success(let chosenMediaURLs):
                    if chosenMediaURLs.isEmpty {
                        logger.info("Media Picker picked nothing")
                    } else {
                        DispatchQueue.main.async {
                            (device._plugins[.share] as? Share)?
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
                        (device._plugins[.share] as? Share)?.prepAndInitFileSend(fileURLs: chosenFileURLs)
                    }
                case .failure(let error):
                    logger.error("Document Picker Error: \(error.localizedDescription, privacy: .public)")
                }
            }
            .onAppear {
                if device._pluginsEnableStatus[.runCommand] as? Bool == true,
                   let runCommand = device._plugins[.runCommand] as? RunCommand {
                    runCommand.requestCommandList()
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
    
    func deviceActionsList(device: Device) -> some View {
        List {
            Section(header: Text("Actions")) {
                if device._pluginsEnableStatus[.clipboard] as? Bool == true {
                    Button {
                        (device._plugins[.clipboard] as? Clipboard)?.sendClipboardContentOut()
                    } label: {
                        Label("Push Local Clipboard", systemImage: "arrow.up.doc.on.clipboard")
                    }
                    .accentColor(.primary)
                }
                
                if device._pluginsEnableStatus[.share] as? Bool == true {
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
                
                if device._pluginsEnableStatus[.presenter] as? Bool == true {
                    NavigationLink(destination: PresenterView(detailsDeviceId: detailsDeviceId)) {
                        Label("Slideshow Remote", systemImage: "slider.horizontal.below.rectangle")
                    }
                    .accentColor(.primary)
                }
                
                if device._pluginsEnableStatus[.runCommand] as? Bool == true,
                   let runCommandPlugin = device._plugins[.runCommand] as? RunCommand {
                    NavigationLink(destination: RunCommandView(runCommandPlugin: runCommandPlugin)) {
                        Label("Run Command", systemImage: "terminal")
                    }
                    .accentColor(.primary)
                }
                
                if device._pluginsEnableStatus[.mousePadRequest] as? Bool == true {
                    NavigationLink(destination: RemoteInputView(detailsDeviceId: self.detailsDeviceId)) {
                        Label("Remote Input", systemImage: "hand.tap")
                    }
                    .accentColor(.primary)
                }
            }
            
            Section(header: Text("Device Status")) {
                BatteryStatus(device: device) { battery in
                    HStack {
                        Label {
                            Text("Battery Level")
                        } icon: {
                            Image(systemName: battery.statusSFSymbolName)
                                .foregroundColor(battery.statusColor)
                        }
                        Spacer()
                        Text("\(percent: battery.remoteChargeLevel)")
                    }
                }
            }
            
            if device._pluginsEnableStatus[.share] as? Bool == true,
               let share = device._plugins[.share] as? Share {
                FileTransferStatusSection(share: share)
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

#endif
