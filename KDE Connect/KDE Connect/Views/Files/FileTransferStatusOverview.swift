//
//  FileTransferStatusOverview.swift
//  KDE Connect
//
//  Created by Apollo Zhu on 4/29/23.
//

import SwiftUI

struct FileTransferStatusOverview: View {
    @EnvironmentObject private var viewModel: ConnectedDevicesViewModel

    let category: FilesTab.Category
    
    private var connectedDevicesIds: [String] {
        viewModel.connectedDevices.keys.sorted()
    }

    var body: some View {
        Section {
            switch category {
            case .receiving:
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
            case .sending:
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
            case .errored:
                EmptyView()
            }
        }
        
        switch category {
        case .receiving:
            EmptyView()
        case .sending:
            ObservingForEachShare(ofDeviceWithIDs: connectedDevicesIds) { deviceID, share in
                if !share.filesToSend.isEmpty {
                    Section {
                        ForEach(share.filesToSend) { file in
                            FileTransferStatus(file: file)
                        }
                    } header: {
                        if let name = viewModel.connectedDevices[deviceID] {
                            Text("Waiting to send to \(name)")
                        }
                    }
                }
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
