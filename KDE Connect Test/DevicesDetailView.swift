//
//  DevicesDetailView.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-06-17.
//

import SwiftUI
import UniformTypeIdentifiers

struct DevicesDetailView: View {
    let detailsDeviceIndex: Int
    @State private var showingEncryptionInfo: Bool = false
    @State private var showingFilePicker: Bool = false
    @State private var chosenFileURLs: [URL] = []
    
    var body: some View {
        List {
            //Text("This is some instructions")
            // NavigationLink doesn't work from the menu in
            // the navigation bar, options are:
            // 1. divide main list into section
            // 2.
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
                    destination: DeviceDetailPluginSettingsView(detailsDeviceIndex: detailsDeviceIndex),
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
        .navigationTitle(testingOtherDevicesInfo[detailsDeviceIndex].connectedDeviceName)
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
                    // unpair alert
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
        .fileImporter(isPresented: $showingFilePicker, allowedContentTypes: allUTTypes, allowsMultipleSelection: true) { result in
            do {
                chosenFileURLs = try result.get()
            } catch {
                print("Document Picker Error")
            }
        }
    }
}

//struct DevicesDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        DevicesDetailView(detailsDeviceIndex: 0)
//    }
//}
