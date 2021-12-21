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
import UIKit

struct DevicesDetailView: View {
    let detailsDeviceId: String
    @State var showingEncryptionInfo: Bool = false
    @State private var showingUnpairConfirmationAlert: Bool = false
    @State private var showingFilePicker: Bool = false
    @State private var showingPluginSettingsView: Bool = false
    
    @State var chosenFileURLs: [URL] = []
    @ObservedObject var viewModel = connectedDevicesViewModel
    
    var isStillConnected: Bool {
        viewModel.connectedDevices.keys.contains(detailsDeviceId)
    }
    
    var body: some View {
        if isStillConnected {
            VStack {
                if #available(iOS 15.0, *) {
                    deviceActionsList
                        .alert("Encryption Info", isPresented: $showingEncryptionInfo) {} message: {
                            Text("SHA256 fingerprint of your device certificate is:\n\((certificateService.hostCertificateSHA256HashFormattedString == nil) ? "ERROR" : certificateService.hostCertificateSHA256HashFormattedString!)\n\nSHA256 fingerprint of remote device certificate is: \n\((backgroundService._devices[detailsDeviceId]!._SHA256HashFormatted == nil || backgroundService._devices[detailsDeviceId]!._SHA256HashFormatted == "") ? "Unable to retrieve fingerprint of remote device. Add the remote device's IP address directly using Configure Devices By IP and Refresh Discovery" : backgroundService._devices[detailsDeviceId]!._SHA256HashFormatted)")
                        }
                        .alert("Unpair With Device?", isPresented: $showingUnpairConfirmationAlert) {
                            Button("No, Stay Paired", role: .cancel) {}
                            Button("Yes, Unpair", role: .destructive) {
                                backgroundService.unpairDevice(detailsDeviceId)
                            }
                        } message: {
                            Text("Unpair with \(backgroundService._devices[detailsDeviceId]!._name)?")
                        }
                } else {
                    // Fallback on earlier versions
                    deviceActionsList
                    
                    iOS14CompatibilityAlert(
                        description: Text("iOS14 Encryption info Alert"),
                        isPresented: $showingEncryptionInfo) {
                            Alert(
                                title: Text("Encryption Info"),
                                message: Text("SHA256 fingerprint of your device certificate is:\n\((certificateService.hostCertificateSHA256HashFormattedString == nil) ? "ERROR" : certificateService.hostCertificateSHA256HashFormattedString!)\n\nSHA256 fingerprint of remote device certificate is: \n\((backgroundService._devices[detailsDeviceId]!._SHA256HashFormatted == nil || backgroundService._devices[detailsDeviceId]!._SHA256HashFormatted == "") ? "Unable to retrive fingerprint of remote device. Add the remote device's IP address directly using Configure Devices By IP and Refresh Discovery" : backgroundService._devices[detailsDeviceId]!._SHA256HashFormatted)")
                            )
                        }
                    
                    iOS14CompatibilityAlert(
                        description: Text("iOS14 Unpairing Alert"),
                        isPresented: $showingUnpairConfirmationAlert) {
                            Alert(
                                title: Text("Unpair With Device?"),
                                message: Text("Unpair with \(backgroundService._devices[detailsDeviceId]!._name)?"),
                                primaryButton: .destructive(Text("Yes, Unpair"), action: {
                                    backgroundService.unpairDevice(detailsDeviceId)
                                }),
                                secondaryButton: .cancel(Text("No, Stay Paired"), action: {})
                            )
                        }
                }
                
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
                        showingEncryptionInfo = true
                    } label: {
                        Label("Encryption Info", systemImage: "lock.doc")
                    }
                    
                    Button {
                        showingUnpairConfirmationAlert = true
                    } label: {
                        Label("Unpair", systemImage: "wifi.slash")
                    }
                    
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            )
            .fileImporter(isPresented: $showingFilePicker, allowedContentTypes: allUTTypes, allowsMultipleSelection: true) { result in
                do {
                    chosenFileURLs = try result.get()
                } catch {
                    print("Document Picker Error")
                }
                if (chosenFileURLs.count > 0) {
                    (backgroundService._devices[detailsDeviceId]!._plugins[.share] as! Share).prepAndInitFileSend(fileURLs: chosenFileURLs)
                }
            }
            .onAppear() {
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
                        showingFilePicker = true
                    } label: {
                        Label("Send files", systemImage: "folder")
                    }
                    .accentColor(.primary)
                }
                
                if ((backgroundService._devices[detailsDeviceId]!._pluginsEnableStatus[.presenter] != nil) && backgroundService._devices[detailsDeviceId]!._pluginsEnableStatus[.presenter] as! Bool) {
                    NavigationLink(destination: PresenterView(detailsDeviceId: detailsDeviceId)) {
                        Label("Slideshow remote", systemImage: "slider.horizontal.below.rectangle")
                    }
                    .accentColor(.primary)
                }
                
                if ((backgroundService._devices[detailsDeviceId]!._pluginsEnableStatus[.runCommand] != nil) && backgroundService._devices[detailsDeviceId]!._pluginsEnableStatus[.runCommand] as! Bool) {
                    NavigationLink(destination: RunCommandView(detailsDeviceId: self.detailsDeviceId)){
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
                                .accentColor(battery.statusColor)
                        }
                        Spacer()
                        Text("\(percent: battery.remoteChargeLevel)")
                    }
                }
            }
        }
        .environment(\.defaultMinListRowHeight, 50) // TODO: make this dynamic with GeometryReader???
    }
}

//struct DevicesDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        DevicesDetailView(detailsDeviceIndex: 0)
//    }
//}
