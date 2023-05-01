/*
 * SPDX-FileCopyrightText: 2023 Apollo Zhu <public-apollonian@outlook.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  FilesHelper.swift
//  KDE Connect
//
//  Created by Apollo Zhu on 4/19/23.
//

import Foundation

extension URL {
    static var defaultDestinationDirectory: URL {
        get throws {
            if #available(iOS 16, *) {
                return .documentsDirectory
            } else {
                return try FileManager.default
                    .url(for: .documentDirectory,
                         in: .userDomainMask,
                         appropriateFor: nil, create: true)
            }
        }
    }
}

extension NSURL {
    @objc static func defaultDestinationDirectory() throws -> NSURL {
        try URL.defaultDestinationDirectory as NSURL
    }
}

enum FilesHelper {
    static func findNonExistingName(for filename: String, at url: URL) -> URL {
        let nsFilename = filename as NSString
        let (name, pathExtension) = (nsFilename.deletingPathExtension, nsFilename.pathExtension)
        
        var id = 1
        var uniqueURL = url.appendingPathComponent(filename)
        do {
            // if file already exists
            while try uniqueURL.checkResourceIsReachable() {
                uniqueURL = url
                    .appendingPathComponent("\(name) (\(id))")
                    .appendingPathExtension(pathExtension)
                let (nextID, overflown) = id.addingReportingOverflow(1)
                guard !overflown else {
                    break
                }
                id = nextID
            }
            // fallback: use a random ID
            let random = ProcessInfo.processInfo.globallyUniqueString
            return url
                .appendingPathComponent("\(name)_\(random)")
                .appendingPathExtension(pathExtension)
        } catch {
            // file not found, okay to use
            return uniqueURL
        }
    }
}
