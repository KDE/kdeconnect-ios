//
//  NetworkPackageComposer.swift
//  KDE Connect
//
//  Created by Apollo Zhu on 3/4/22.
//

import SwiftUI
import Introspect

struct NetworkPackageComposer: View {
    @State private var networkPackageToSend: String = ""
    @State private var tag: Int = 0
    @State private var npType: NetworkPackage.`Type` = .identity
    @State private var deviceID: String = ""
    @EnvironmentObject private var connectedDevicesViewModel: ConnectedDevicesViewModel
    @EnvironmentObject private var selfDeviceData: SelfDeviceData
    private let logger = Logger()
    
    var body: some View {
        Form {
            Section {
                Picker("Device", selection: $deviceID) {
                    ForEach(connectedDevicesViewModel.connectedDevices.keys.sorted(), id: \.self) { deviceID in
                        Text(connectedDevicesViewModel.connectedDevices[deviceID] ?? deviceID)
                            .tag(deviceID)
                    }
                    ForEach(connectedDevicesViewModel.visibleDevices.keys.sorted(), id: \.self) { deviceID in
                        Text(connectedDevicesViewModel.visibleDevices[deviceID] ?? deviceID)
                            .tag(deviceID)
                    }
                }
                .onAppear {
                    let connectedIDs = connectedDevicesViewModel.connectedDevices.keys
                    let visibleIDs = connectedDevicesViewModel.visibleDevices.keys
                    if connectedIDs.count + visibleIDs.count == 1 {
                        deviceID = connectedIDs.first ?? visibleIDs.first ?? ""
                    }
                }
                
                Picker("Package Type", selection: $npType) {
                    ForEach(NetworkPackage.allPackageTypes, id: \.self) { type in
                        Text(type.rawValue)
                            .font(.system(.body, design: .monospaced))
                    }
                }
                
                Picker("Package Tag", selection: $tag) {
                    ForEach(NetworkPackage.allPackageTags, id: \.self) { tag in
                        Text(NetworkPackage.description(for: tag))
                            .font(.system(.body, design: .monospaced))
                    }
                }
            }
            
            Section {
                TextEditor(text: $networkPackageToSend)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(isValidPackageBody ? nil : .red)
                    .autocapitalization(.none)
                    .introspectTextView { textView in
                        textView.smartQuotesType = .no
                    }
                    .onChange(of: networkPackageToSend) { newValue in
                        if newValue == "isDebuggingNetworkPackage" {
                            withAnimation {
                                selfDeviceData.isDebuggingNetworkPackage = true
                            }
                        }
                    }
            } header: {
                Text("Package Body")
            } footer: {
                Label {
                    Text(isValidPackageBody ? LocalizedStringKey("Valid") : LocalizedStringKey("Invalid"))
                        .foregroundColor(isValidPackageBody ? nil : .red)
                } icon: {
                    Image(systemName: isValidPackageBody ? "checkmark.circle.fill" : "x.circle.fill")
                        .foregroundColor(isValidPackageBody ? .green : .red)
                }
            }
            
            Button {
                guard let device = backgroundService._devices[deviceID] else {
                    logger.error("No device with ID \(deviceID, privacy: .private(mask: .hash))")
                    return
                }
                let np = NetworkPackage(type: npType)
                do {
                    if !networkPackageToSend.isEmpty {
                        np._Body = try packageBody
                    }
                } catch {
                    logger.info("Not JSON because \(error.localizedDescription, privacy: .public)")
                }
                device.send(np, tag: tag)
            } label: {
                Label {
                    Text("Send Network Package")
                } icon: {
                    if selfDeviceData.isDebuggingNetworkPackage {
                        Image(systemName: "hammer.fill")
                    }
                }
            }
            .disabled(deviceID.isEmpty
                      || !isValidPackageBody
                      || !(connectedDevicesViewModel.connectedDevices.keys.contains(deviceID)
                           || connectedDevicesViewModel.visibleDevices.keys.contains(deviceID)))
        }
        .navigationTitle("Network Package Composer")
    }
    
    private var isValidPackageBody: Bool {
        networkPackageToSend.isEmpty || (try? packageBody) != nil
    }
    
    private var packageBody: NSMutableDictionary {
        get throws {
            let body = try JSONSerialization.jsonObject(with: Data(networkPackageToSend.utf8),
                                                        options: .mutableContainers)
            if let dictionary = body as? NSMutableDictionary {
                return dictionary
            } else {
                logger.fault("JSON not convertible to NSMutableDictionary")
                throw Errors.notDictionary
            }
        }
    }
    
    private enum Errors: LocalizedError {
        case notDictionary
        
        var errorDescription: String? {
            switch self {
            case .notDictionary: return "Top level JSON is not a dictionary."
            }
        }
    }
}

struct NetworkPackageComposer_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NetworkPackageComposer()
        }
    }
}
