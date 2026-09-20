//
//  FileTransferStatusOverview.swift
//  KDE Connect
//
//  Created by Apollo Zhu on 4/29/23.
//

#if !os(macOS)

import SwiftUI

struct FileTransferStatusOverview: View {
    @EnvironmentObject private var viewModel: ConnectedDevicesViewModel

    let category: FilesTab.Category
    
    private var connectedDevicesIds: [String] {
        viewModel.connectedDevices.keys.sorted()
    }
    
    private func hasAny(_ keyPath: KeyPath<Share, some Collection>) -> Bool {
        connectedDevicesIds.contains { deviceID in
            guard let device = backgroundService._devices[deviceID],
                  device._pluginsEnableStatus[.share] as? Bool == true,
                  let share = device._plugins[.share] as? Share
            else { return false }
            return !share[keyPath: keyPath].isEmpty
        }
    }
    
    private var hasReceivingFiles: Bool {
        hasAny(\.currentFilesReceiving.keys)
    }
    
    private var hasSendingFiles: Bool {
        hasAny(\.currentFilesSending.keys)
    }
    
    private var hasFilesWaitingToSend: Bool {
        hasAny(\.filesToSend)
    }

    var body: some View {
        switch category {
        case .receiving where hasReceivingFiles:
            Section {
                ObservingForEachShare(ofDeviceWithIDs: connectedDevicesIds) { deviceID, share in
                    ForEach(share.currentFilesReceiving.values) { file in
                        FileTransferStatus(file: file) {
                            if let name = viewModel.connectedDevices[deviceID] {
                                Text("From \(Text(name).bold())")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }
            } header: {
                Text("Receiving")
            }
        case .sending where hasSendingFiles:
            Section {
                ObservingForEachShare(ofDeviceWithIDs: connectedDevicesIds) { deviceID, share in
                    ForEach(share.currentFilesSending.values) { file in
                        FileTransferStatus(file: file) {
                            if let name = viewModel.connectedDevices[deviceID] {
                                Text("To \(Text(name).bold())")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }
            } header: {
                Text("Sending")
            }
        default:
            EmptyView()
        }
        
        switch category {
        case .sending where hasFilesWaitingToSend:
            Section {
                ObservingForEachShare(ofDeviceWithIDs: connectedDevicesIds) { deviceID, share in
                    if !share.filesToSend.isEmpty {
                        ForEach(share.filesToSend) { file in
                            FileTransferStatus(file: file) {
                                if let name = viewModel.connectedDevices[deviceID] {
                                    Text("To \(Text(name).bold())")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
            } header: {
                Text("Waiting to send")
            }
        case .errored:
            ObservingForEachShare(ofDeviceWithIDs: connectedDevicesIds) { deviceID, share in
                if !share.filesFailedToReceive.isEmpty {
                    Section {
                        ForEach(share.filesFailedToReceive) { transfer in
                            FailedFileTransferDisplay(transfer: transfer)
                        }
                        .onDelete { offsets in
                            share.filesFailedToReceive.remove(atOffsets: offsets)
                        }
                    } header: {
                        if let name = viewModel.connectedDevices[deviceID] {
                            Text("Failed to receive from \(name)")
                        }
                    }
                }
                
                if !share.filesFailedToSend.isEmpty {
                    Section {
                        ForEach(share.filesFailedToSend) { transfer in
                            FailedFileTransferDisplay(transfer: transfer)
                        }
                        .onDelete { offsets in
                            share.filesFailedToSend.remove(atOffsets: offsets)
                        }
                    } header: {
                        if let name = viewModel.connectedDevices[deviceID] {
                            Text("Failed to send to \(name)")
                        }
                    }
                }
            }
        default:
            EmptyView()
        }
    }
}

struct ObservingForEachShare<Content: View>: View {
    let deviceIDs: [String]
    let content: (String, Share) -> Content
    
    init(
        ofDeviceWithIDs deviceIDs: [String],
        @ViewBuilder content: @escaping (String, Share) -> Content
    ) {
        self.deviceIDs = deviceIDs
        self.content = content
    }
    
    private struct Observing: View {
        let deviceID: String
        @ObservedObject var share: Share
        let content: (String, Share) -> Content
        
        var body: some View {
            content(deviceID, share)
        }
    }
    
    var body: some View {
        ForEach(deviceIDs, id: \.self) { deviceID in
            if let device = backgroundService._devices[deviceID],
               device._pluginsEnableStatus[.share] as? Bool == true {
                Observing(deviceID: deviceID,
                          share: device._plugins[.share] as! Share,
                          content: content)
            }
        }
    }
}

struct FileTransferStatusOverview_Previews: PreviewProvider {
    @State static var category: FilesTab.Category = .receiving
    
    static var previews: some View {
        FileTransferStatusOverview(category: category)
            .environmentObject(connectedDevicesViewModel)
    }
}

#endif
