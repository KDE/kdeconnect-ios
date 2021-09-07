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
    
    var body: some View {
        if (isStilConnected) {
            VStack {
                List {
                    Section(header: Text("Actions")) {
                        Button(action: {
                            showingFilePicker = true
                        }, label: {
                            HStack {
                                Image(systemName: "folder")
                                Text("Send files")
                            }
                        })
                        
                        Button(action: {
                            ((backgroundService._devices[detailsDeviceId as Any] as! Device)._plugins[PACKAGE_TYPE_CLIPBOARD] as! Clipboard).sendClipboardContentOut()
                        }, label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up.on.square.fill")
                                Text("Push Local Clipboard")
                            }
                        })
                        
//                        NavigationLink(
//                            destination: PlaceHolderView(),
//                            label: {
//                                HStack {
//                                    Image(systemName: "slider.horizontal.below.rectangle")
//                                    Text("Slideshow remote")
//                                }
//                            })
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
                        NavigationLink(
                            destination: RemoteInputView(detailsDeviceId: self.detailsDeviceId),
                            label: {
                                HStack {
                                    Image(systemName: "hand.tap")
                                    Text("Remote input")
                                }
                            })
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
                
            }
            .navigationTitle((backgroundService._devices[detailsDeviceId] as! Device)._name)
            .navigationBarItems(trailing: {
                Menu {
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
                    
                    Button(action: {
                        // ring
                    }, label: {
                        HStack {
                            Text("Ring Device")
                            Image(systemName: "bell")
                        }
                    })
                    
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
                for url in chosenFileURLs {
                    ((backgroundService._devices[detailsDeviceId as Any] as! Device)._plugins[PACKAGE_TYPE_SHARE] as! Share).sendFile(fileURL: url)
//                    do {
//                        sleep(2)
//                    }
                }
            }
            .onAppear() {
                connectedDevicesViewModel.currDeviceDetailsView = self
                (backgroundService._devices[detailsDeviceId] as! Device)._backgroundServiceDelegate = connectedDevicesViewModel
                //print((backgroundService._devices[detailsDeviceId] as! Device)._plugins as Any)
                //print((backgroundService._devices[detailsDeviceId] as! Device)._incomingCapabilities as Any)
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
