/*
 * SPDX-FileCopyrightText: 2022 Apollo Zhu <public-apollonian@outlook.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

//
//  FileTransferStatusSection.swift
//  KDE Connect
//
//  Created by Apollo Zhu on 11/3/22.
//

import SwiftUI
import OrderedCollections
import struct CocoaAsyncSocket.GCDAsyncSocketError

struct FileTransferStatus<Content: View>: View {
    let file: FileTransferItemInfo
    let subtitle: Content
    
    init(file: FileTransferItemInfo, @ViewBuilder subtitle: () -> Content = { EmptyView() }) {
        self.file = file
        self.subtitle = subtitle()
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(file.name)
                .fixedSize(horizontal: false, vertical: true)
            
            if let total = file.totalBytes {
                let completed = file.totalBytesCompleted
                
                ProgressView(value: Double(completed), total: Double(total))
                    .animation(.default, value: file.totalBytesCompleted)
                
                HStack {
                    subtitle
                    
                    Spacer()
                    
                    Text("\(Int64(completed), format: .byteCount(style: .file)) / \(Int64(total), format: .byteCount(style: .file))")
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .monospacedDigit()
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                HStack(spacing: 8) {
                    subtitle
                    
                    Spacer()
                    
                    Text("\(Int64(file.totalBytesCompleted), format: .byteCount(style: .file))")
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .monospacedDigit()
                        .fixedSize(horizontal: false, vertical: true)
                    
                    ProgressView()
                }
            }
        }
    }
}

struct FailedFileTransferDisplay: View {
    let transfer: FailedFileTransferItemInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let unnamedCount = transfer.countOtherFailedFilesInTheSameTransfer
            if unnamedCount > 0 {
                Text("\(transfer.name) and \(unnamedCount) other files")
            } else {
                Text(transfer.name)
            }
            
            Text(transfer.error.localizedDescription)
                .font(.caption)
        }
        .foregroundColor(.red)
    }
}

struct FileTransferStatusSection: View {
    @ObservedObject var share: Share
    
    var body: some View {
        filesFailedToReceive
        
        filesToReceive
        
        filesFailedToSend
        
        filesToSend
    }
    
    @ViewBuilder
    var filesToSend: some View {
        if share.totalNumOfFilesToSend > 0 {
            Section {
                ForEach(share.currentFilesSending.values) { file in
                    FileTransferStatus(file: file)
                }
                
                ForEach(share.filesToSend) { file in
                    FileTransferStatus(file: file)
                }
            } header: {
                Text("Sending file \(share.numFilesSuccessfullySent + 1) of \(share.totalNumOfFilesToSend)")
                    .monospacedDigit()
            }
        }
    }
    
    @ViewBuilder
    var filesFailedToSend: some View {
        if !share.filesFailedToSend.isEmpty {
            Section {
                ForEach(share.filesFailedToSend) { transfer in
                    FailedFileTransferDisplay(transfer: transfer)
                }
                .onDelete { offsets in
                    share.filesFailedToSend.remove(atOffsets: offsets)
                }
            } header: {
                Label {
                    let total = share.filesFailedToSend.reduce(0) {
                        $0 + 1 + $1.countOtherFailedFilesInTheSameTransfer
                    }
                    Text("Failed to send \(total) files")
                        .monospacedDigit()
                } icon: {
                    Image(systemName: "exclamationmark.triangle")
                }
            }
        }
    }
    
    @ViewBuilder
    var filesFailedToReceive: some View {
        if !share.filesFailedToReceive.isEmpty {
            Section {
                ForEach(share.filesFailedToReceive) { transfer in
                    FailedFileTransferDisplay(transfer: transfer)
                }
                .onDelete { offsets in
                    share.filesFailedToReceive.remove(atOffsets: offsets)
                }
            } header: {
                Label {
                    let total = share.filesFailedToReceive.reduce(0) {
                        $0 + 1 + $1.countOtherFailedFilesInTheSameTransfer
                    }
                    Text("Failed to receive \(total) files")
                        .monospacedDigit()
                } icon: {
                    Image(systemName: "exclamationmark.triangle")
                }
            }
        }
    }
    
    @ViewBuilder
    var filesToReceive: some View {
        if share.totalNumOfFilesToReceive > 0 {
            Section {
                let remaining = share.totalNumOfFilesToReceive
                    - share.numFilesReceived
                    - share.currentFilesReceiving.count
                if remaining > 0 {
                    Text("Waiting for \(remaining) other files to start transferring")
                        .monospacedDigit()
                }
                
                ForEach(share.currentFilesReceiving.values) { file in
                    FileTransferStatus(file: file)
                }
            } header: {
                Text("Receiving file \(share.numFilesReceived + share.currentFilesReceiving.count) of \(share.totalNumOfFilesToReceive)")
                    .monospacedDigit()
            }
        }
    }
}

struct FileTransferStatusSection_Previews: PreviewProvider {
    static let share = Share(controlDevice: Device(
        id: "test", type: .unknown, name: "Test",
        incomingCapabilities: [],
        outgoingCapabilities: [],
        protocolVersion: -1, deviceDelegate: nil
    ))
    
    private static func setupForFileTransferUIPreview(in share: Share) {
        share.totalNumOfFilesToSend = 5
        share.numFilesSuccessfullySent = 2
        share.filesFailedToSend = [
            .init(path: URL(string: "file://1.png")!,
                  name: "Not working.png",
                  error: POSIXError(POSIXErrorCode(rawValue: 32)!),
                  countOtherFailedFilesInTheSameTransfer: 0),
        ]
        share.currentFilesSending = OrderedDictionary(uniqueKeysWithValues: [
            .init(path: URL(string: "file://3.jpg")!,
                  name: "3.jpg",
                  totalBytes: 9876543,
                  totalBytesCompleted: Int.random(in: 0...9876543)),
        ].map { ($0.path, $0) })
        share.filesToSend = [
            .init(path: URL(string: "file://4.swift")!,
                  name: "slightly longer.swift",
                  totalBytes: 1024,
                  totalBytesCompleted: Int.random(in: 0...1024)),
            .init(path: URL(string: "file://5.tar.gz")!,
                  name: "this_IS_super_long-FILENAME_0.1.0.tar.gz",
                  totalBytes: 1234567890,
                  totalBytesCompleted: Int.random(in: 0...1234567890)),
        ]
        share.totalNumOfFilesToReceive = 10
        share.numFilesReceived = 2
        share.currentFilesReceiving = OrderedDictionary(uniqueKeysWithValues: [
            .init(path: URL(string: "file://2.png")!,
                  name: "2.png",
                  totalBytes: nil,
                  totalBytesCompleted: 1),
            .init(path: URL(string: "file://var/tmp/3.mp4")!,
                  name: "😅 Unicode 哦.mp4",
                  totalBytes: Int.max,
                  totalBytesCompleted: Int.random(in: 0...Int.max)),
        ].map { ($0.path, $0) })
        // Localization: although error messages from CocoaAsyncSocket supports
        // been translated, however the default Export Localizations... action
        // does not attempt to include the GCDAsyncSocket translation table.
        // Therefore, if we directly show the error messages to users,
        // they'll seen an unlocalized error message.
        let connectionClosed = GCDAsyncSocketError(
            .closedError,
            userInfo: [
                NSLocalizedDescriptionKey: "Socket closed by remote peer",
            ]
        )
        share.filesFailedToReceive = [
            .init(path: URL(string: "file://wat.png")!,
                  name: "wAt.png",
                  error: connectionClosed,
                  countOtherFailedFilesInTheSameTransfer: 2),
        ]
    }
    
    static let timer = Timer
        .publish(every: 2, on: .main, in: .common)
        .autoconnect()
    
    static var previews: some View {
        NavigationView {
            List {
                FileTransferStatusSection(share: share)
            }
            .navigationTitle("Device Name")
            .onAppear {
                setupForFileTransferUIPreview(in: share)
            }
            .onReceive(timer) { _ in
                setupForFileTransferUIPreview(in: share)
            }
        }
    }
}
