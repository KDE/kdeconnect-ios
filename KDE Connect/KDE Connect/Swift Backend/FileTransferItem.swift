/*
 * SPDX-FileCopyrightText: 2023 Apollo Zhu <public-apollonian@outlook.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

//
//  FileTransferItem.swift
//  KDE Connect
//
//  Created by Apollo Zhu on 2/20/23.
//

import Foundation
import CocoaAsyncSocket

@objc(KDEFileTransferItem)
@objcMembers
class FileTransferItem: NSObject {
    let fileHandle: FileHandle
    let networkPackage: NetworkPackage
    private(set) var info: FileTransferItemInfo
    let buffer = NSMutableData()
    
    init?(fileHandle: FileHandle, networkPackage: NetworkPackage) {
        self.fileHandle = fileHandle
        self.networkPackage = networkPackage
        guard let path = networkPackage.payloadPath else {
            preconditionFailure("NetworkPackage missing payloadPath")
        }
        guard let name = networkPackage._Body["filename"] as? String else {
            preconditionFailure("file transfer package missing filename")
        }
        self.info = FileTransferItemInfo(
            path: path,
            name: name,
            creationEpoch: networkPackage._Body["creationTime"] as? Int64,
            lastModifiedEpoch: networkPackage._Body["lastModified"] as? Int64,
            totalBytes: networkPackage._PayloadSize == -1 ? nil : networkPackage._PayloadSize
        )
        super.init()
    }
    
    var totalBytes: NSNumber? { info.totalBytes as? NSNumber }
    
    var totalBytesCompleted: Int {
        get { info.totalBytesCompleted }
        set { info.totalBytesCompleted = newValue }
    }
}

struct FileTransferItemInfo: Equatable, Identifiable {
    let path: URL
    let name: String
    let creationEpoch: Int64?
    let lastModifiedEpoch: Int64?
    let totalBytes: Int?
    var totalBytesCompleted: Int = 0
    
    var id: URL { path }
}

extension FileTransferItemInfo {
    init(path: URL, name: String, totalBytes: Int?, totalBytesCompleted: Int = 0) {
        self.init(path: path, name: name,
                  creationEpoch: nil, lastModifiedEpoch: nil,
                  totalBytes: totalBytes, totalBytesCompleted: totalBytesCompleted)
    }
}

struct FailedFileTransferItemInfo: Identifiable {
    let path: URL
    let name: String
    let error: Error
    /// Sometimes file transfers are packaged together and we don't know
    /// exact file names, so the other related files are just a number.
    let countOtherFailedFilesInTheSameTransfer: Int
    
    var id: URL { path }
}
