//
//  NetworkPacketComposer.swift
//  KDE Connect
//
//  Created by Apollo Zhu on 3/4/22.
//

#if !os(macOS)

import SwiftUI
import Introspect

struct NetworkPacketComposer: View {
    @State private var networkPacketToSend: String = ""
    @State private var tag: Int = 0
    @State private var npType: NetworkPacket.`Type` = .identity
    @State private var deviceID: String = ""
    @EnvironmentObject private var connectedDevicesViewModel: ConnectedDevicesViewModel
    @EnvironmentObject private var kdeConnectSettings: KdeConnectSettings
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
                
                Picker("Packet Type", selection: $npType) {
                    ForEach(NetworkPacket.allPacketTypes, id: \.self) { type in
                        Text(type.rawValue)
                            .font(.system(.body, design: .monospaced))
                    }
                }
                
                Picker("Packet Tag", selection: $tag) {
                    ForEach(NetworkPacket.allPacketTags, id: \.self) { tag in
                        Text(NetworkPacket.description(for: tag))
                            .font(.system(.body, design: .monospaced))
                    }
                }
            }
            
            Section {
                TextEditor(text: $networkPacketToSend)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(isValidPacketBody ? nil : .red)
                    .autocapitalization(.none)
                    .introspectTextView { textView in
                        textView.smartQuotesType = .no
                    }
                    .onChange(of: networkPacketToSend) { newValue in
                        if newValue == "isDebuggingNetworkPacket" {
                            withAnimation {
                                kdeConnectSettings.isDebuggingNetworkPacket = true
                            }
                        }
                    }
            } header: {
                Text("Packet Body")
            } footer: {
                Label {
                    Text(isValidPacketBody ? LocalizedStringKey("Valid") : LocalizedStringKey("Invalid"))
                        .foregroundColor(isValidPacketBody ? nil : .red)
                } icon: {
                    Image(systemName: isValidPacketBody ? "checkmark.circle.fill" : "x.circle.fill")
                        .foregroundColor(isValidPacketBody ? .green : .red)
                }
            }
            
            Button {
                guard let device = backgroundService._devices[deviceID] else {
                    logger.error("No device with ID \(deviceID, privacy: .private(mask: .hash))")
                    return
                }
                let np = NetworkPacket(type: npType)
                do {
                    if !networkPacketToSend.isEmpty {
                        np._Body = try packetBody
                    }
                } catch {
                    logger.info("Not JSON because \(error.localizedDescription, privacy: .public)")
                }
                device.send(np, tag: tag)
            } label: {
                Label {
                    Text("Send Network Packet")
                } icon: {
                    if kdeConnectSettings.isDebuggingNetworkPacket {
                        Image(systemName: "hammer.fill")
                    }
                }
            }
            .disabled(deviceID.isEmpty
                      || !isValidPacketBody
                      || !(connectedDevicesViewModel.connectedDevices.keys.contains(deviceID)
                           || connectedDevicesViewModel.visibleDevices.keys.contains(deviceID)))
        }
        .navigationTitle("Network Packet Composer")
    }
    
    private var isValidPacketBody: Bool {
        networkPacketToSend.isEmpty || (try? packetBody) != nil
    }
    
    private var packetBody: NSMutableDictionary {
        get throws {
            let body = try JSONSerialization.jsonObject(with: Data(networkPacketToSend.utf8),
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

struct NetworkPacketComposer_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NetworkPacketComposer()
        }
    }
}

#endif
