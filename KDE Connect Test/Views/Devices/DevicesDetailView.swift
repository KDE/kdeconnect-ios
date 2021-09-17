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
    @State var isStilConnected: Bool = true
    @State private var showingPluginSettingsView: Bool = false
    
    @State var chosenFileURLs: [URL] = []
    
    // TODO: Maybe use a state to directly change the Battery % instead of doing this hacky thing?
    @State var batteryUpdate: Bool = false
    
    var body: some View {
        if (isStilConnected) {
            VStack {
                List {
                    Section(header: Text("Actions")) {
                        if ((backgroundService._devices[detailsDeviceId as Any] as! Device)._pluginsEnableStatus[PACKAGE_TYPE_SHARE] as! Bool) {
                            Button(action: {
                                showingFilePicker = true
                            }, label: {
                                HStack {
                                    Image(systemName: "folder")
                                    Text("Send files")
                                }
                            })
                        }
                        
                        if ((backgroundService._devices[detailsDeviceId as Any] as! Device)._pluginsEnableStatus[PACKAGE_TYPE_CLIPBOARD] as! Bool) {
                            Button(action: {
                                ((backgroundService._devices[detailsDeviceId as Any] as! Device)._plugins[PACKAGE_TYPE_CLIPBOARD] as! Clipboard).sendClipboardContentOut()
                            }, label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.up.on.square.fill")
                                    Text("Push Local Clipboard")
                                }
                            })
                        }
                        
                        if ((backgroundService._devices[detailsDeviceId as Any] as! Device)._pluginsEnableStatus[PACKAGE_TYPE_PRESENTER] as! Bool) {
                            NavigationLink(
                                destination: PresenterView(detailsDeviceId: detailsDeviceId),
                                label: {
                                    HStack {
                                        Image(systemName: "slider.horizontal.below.rectangle")
                                        Text("Slideshow remote")
                                    }
                                })
                        }
//
//                        NavigationLink(
//                            destination: PlaceHolderView(),
//                            label: {
//                                HStack {
//                                    Image(systemName: "playpause")
//                                    Text("Multimedia control")
//                                }
//                            })
//
                        
                        if ((backgroundService._devices[detailsDeviceId as Any] as! Device)._pluginsEnableStatus[PACKAGE_TYPE_RUNCOMMAND] as! Bool) {
                            NavigationLink(
                                destination: RunCommandView(detailsDeviceId: self.detailsDeviceId),
                                label: {
                                    HStack {
                                        Image(systemName: "terminal")
                                        Text("Run Command")
                                    }
                                })
                        }
                        
                        if (((backgroundService._devices[detailsDeviceId as Any] as! Device)._pluginsEnableStatus[PACKAGE_TYPE_MOUSEPAD_REQUEST] as! Bool)) {
                            NavigationLink(
                                destination: RemoteInputView(detailsDeviceId: self.detailsDeviceId),
                                label: {
                                    HStack {
                                        Image(systemName: "hand.tap")
                                        Text("Remote input")
                                    }
                                })
                        }
                    }
                    
                    Section(header: Text("Battery Status")) {
                        if (!((backgroundService._devices[detailsDeviceId] as! Device)._pluginsEnableStatus[PACKAGE_TYPE_BATTERY_REQUEST] as! Bool)) {
                            Text("Battery Plugin Disabled")
                        } else if ((backgroundService._devices[detailsDeviceId] as! Device)._type != DeviceType.Desktop) {
                            HStack {
                                Image(systemName: ((backgroundService._devices[detailsDeviceId] as! Device)._plugins[PACKAGE_TYPE_BATTERY_REQUEST] as! Battery).getSFSymbolNameFromBatteryStatus())
                                    .font(.system(size: 18))
                                    .foregroundColor(((backgroundService._devices[detailsDeviceId] as! Device)._plugins[PACKAGE_TYPE_BATTERY_REQUEST] as! Battery).getSFSymbolColorFromBatteryStatus())
                                Text("\(((backgroundService._devices[detailsDeviceId] as! Device)._plugins[PACKAGE_TYPE_BATTERY_REQUEST] as! Battery).remoteChargeLevel)%")
                                    .font(.system(size: 18))
                            }
                        } else {
                            Text("No battery detected in device")
                        }
                    }
                    
                    //            Section(header: Text("Debug section")) {
                    //                Text("Chosen file URLs:")
                    //                ForEach(chosenFileURLs, id: \.self) { url in
                    //                    Text(url.absoluteString)
                    //                }
                    //            }
                    
                }
                .environment(\.defaultMinListRowHeight, 50) // TODO: make this dynamic with GeometryReader???
                
                NavigationLink(destination: DeviceDetailPluginSettingsView(detailsDeviceId: self.detailsDeviceId), isActive: $showingPluginSettingsView) {
                    EmptyView()
                }
                
                // This is an invisible view using changes in batteryUpdate to force SwiftUI to re-render the entire screen. We want this because the battery information is NOT a @State variables, as such in order for updates to actually register, we need to force the view to re-render
                Text(batteryUpdate ? "True" : "False")
                    .opacity(0)
                
            }
            .navigationTitle((backgroundService._devices[detailsDeviceId] as! Device)._name)
            .navigationBarItems(trailing: {
                Menu {
                    if ((backgroundService._devices[detailsDeviceId as Any] as! Device)._pluginsEnableStatus[PACKAGE_TYPE_PING] as! Bool) {
                        Button(action: {
                            //print(backgroundService._devices[detailsDeviceId as Any] as! Device)
                            //print((backgroundService._devices[detailsDeviceId as Any] as! Device)._plugins[PACKAGE_TYPE_PING] as! Ping)
                            ((backgroundService._devices[detailsDeviceId as Any] as! Device)._plugins[PACKAGE_TYPE_PING] as! Ping).sendPing()
                        }, label: {
                            HStack {
                                Text("Send Ping")
                                Image(systemName: "megaphone")
                            }
                        })
                    }
                    
                    if ((backgroundService._devices[detailsDeviceId as Any] as! Device)._pluginsEnableStatus[PACKAGE_TYPE_FINDMYPHONE_REQUEST] as! Bool) {
                        Button(action: {
                            ((backgroundService._devices[detailsDeviceId as Any] as! Device)._plugin[PACKAGE_TYPE_FINDMYPHONE_REQUEST] as! FindMyPhone).sendFindMyPhoneRequest()
                        }, label: {
                            HStack {
                                Text("Ring Device")
                                Image(systemName: "bell")
                            }
                        })
                    }
                    
                    Button(action: {
                        showingPluginSettingsView = true
                    }, label: {
                        HStack {
                            Image(systemName: "dot.arrowtriangles.up.right.down.left.circle")
                            Text("Plugin Settings")
                        }
                    })
                    
                    Button(action: {
                        showingEncryptionInfo = true
                    }, label: {
                        HStack {
                            Text("Encryption Info")
                            Image(systemName: "lock.doc")
                        }
                    })
                    
                    Button(action: {
                        showingUnpairConfirmationAlert = true
                    }, label: {
                        HStack {
                            Text("Unpair")
                            Image(systemName: "wifi.slash")
                        }
                    })
                    
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }())
            .alert(isPresented: $showingEncryptionInfo) {
                Alert(title: Text("Encryption Info"), message:
                        Text("SHA256 fingerprint of your device certificate is:\ndfdsfsfsdfsdfsdfsdf\n\nSHA256 fingerprint of remote device certificate is:\nDFSDFSDFSDF")
                      , dismissButton: .default(Text("OK")))
            }
            .alert(isPresented: $showingUnpairConfirmationAlert) {
                Alert(title: Text("Unpair With Device?"),
                      message: Text("Unpair with \((backgroundService._devices[detailsDeviceId] as! Device)._name)?"),
                      primaryButton: .cancel(Text("No, Stay Paired")),
                      secondaryButton: .destructive(
                        Text("Yes, Unpair")
                      ) {
                        backgroundService.unpairDevice(detailsDeviceId)
                        isStilConnected = false
//                        backgroundService.refreshDiscovery()
//                        connectedDevicesViewModel.onDeviceListRefreshed()
                      }
                )
            }
            .fileImporter(isPresented: $showingFilePicker, allowedContentTypes: allUTTypes, allowsMultipleSelection: true) { result in
                do {
                    chosenFileURLs = try result.get()
                } catch {
                    print("Document Picker Error")
                }
                if (chosenFileURLs.count > 0) {
                    ((backgroundService._devices[detailsDeviceId as Any] as! Device)._plugins[PACKAGE_TYPE_SHARE] as! Share).prepAndInitFileSend(fileURLs: chosenFileURLs)
                }
            }
            .onAppear() {
                connectedDevicesViewModel.currDeviceDetailsView = self
                (backgroundService._devices[detailsDeviceId] as! Device)._backgroundServiceDelegate = connectedDevicesViewModel
                //print((backgroundService._devices[detailsDeviceId] as! Device)._plugins as Any)
                //print((backgroundService._devices[detailsDeviceId] as! Device)._incomingCapabilities as Any)
                if ((backgroundService._devices[detailsDeviceId] as! Device)._pluginsEnableStatus[PACKAGE_TYPE_RUNCOMMAND] as! Bool) {
                    ((backgroundService._devices[detailsDeviceId] as! Device)._plugins[PACKAGE_TYPE_RUNCOMMAND] as! RunCommand).requestCommandList()
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
            // Calling this here will refresh after getting to the DeviceView, a bit of delay b4 the
            // list actually refreshes but still works
//            .onDisappear() {
//                connectedDevicesViewModel.devicesView!.refreshDiscoveryAndList()
//            }
        }
    }
}

//struct DevicesDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        DevicesDetailView(detailsDeviceIndex: 0)
//    }
//}
