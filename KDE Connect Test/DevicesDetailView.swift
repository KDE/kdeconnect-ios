//
//  DevicesDetailView.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-06-17.
//

import SwiftUI
import UniformTypeIdentifiers

struct DevicesDetailView: View {
    let detailsDeviceId: String
    @State var showingEncryptionInfo: Bool = false
    @State private var showingUnpairConfirmationAlert: Bool = false
    @State private var showingFilePicker: Bool = false
    @State var isStilConnected: Bool = true
    
    @State var chosenFileURLs: [URL] = []
    
    var body: some View {
        if (isStilConnected) {
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
                    
                    NavigationLink(
                        destination: PlaceHolderView(),
                        label: {
                            HStack {
                                Image(systemName: "slider.horizontal.below.rectangle")
                                Text("Slideshow remote")
                            }
                        })
                    
                    NavigationLink(
                        destination: PlaceHolderView(),
                        label: {
                            HStack {
                                Image(systemName: "playpause")
                                Text("Multimedia control")
                            }
                        })
                    
                    NavigationLink(
                        destination: PlaceHolderView(),
                        label: {
                            HStack {
                                Image(systemName: "hand.tap")
                                Text("Remote input")
                            }
                        })
                }
                Section(header: Text("Device Specific Settings")) {
                    NavigationLink(
                        destination: PlaceHolderView(), //DeviceDetailPluginSettingsView(detailsDeviceIndex: detailsDeviceIndex)
                        label: {
                            HStack {
                                Image(systemName: "dot.arrowtriangles.up.right.down.left.circle")
                                Text("Plugin Settings")
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
            .navigationTitle((backgroundService._devices[detailsDeviceId] as! Device)._name)
            .navigationBarItems(trailing: {
                Menu {
                    Button(action: {
                        // ring
                    }, label: {
                        HStack {
                            Text("Ring")
                            Image(systemName: "bell")
                        }
                    })
                    
                    Button(action: {
                        // send ping
                    }, label: {
                        HStack {
                            Text("Send Ping")
                            Image(systemName: "megaphone")
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
                        backgroundService.refreshDiscovery()
                        connectedDevicesViewModel.onDeviceListRefreshed()
                      }
                )
            }
            .fileImporter(isPresented: $showingFilePicker, allowedContentTypes: allUTTypes, allowsMultipleSelection: true) { result in
                do {
                    chosenFileURLs = try result.get()
                } catch {
                    print("Document Picker Error")
                }
            }
            .onAppear() {
                connectedDevicesViewModel.currDeviceDetailsView = self
                (backgroundService._devices[detailsDeviceId] as! Device)._backgroundServiceDelegate = connectedDevicesViewModel
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
