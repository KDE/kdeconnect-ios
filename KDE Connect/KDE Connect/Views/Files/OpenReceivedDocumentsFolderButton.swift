/*
 * SPDX-FileCopyrightText: 2023 Apollo Zhu <public-apollonian@outlook.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

//
//  OpenReceivedDocumentsFolderButton.swift
//  KDE Connect
//
//  Created by Apollo Zhu on 4/12/23.
//

import SwiftUI

struct OpenReceivedDocumentsFolderButton: View {
    @Environment(\.openURL) var openURL
    let logger = Logger()
    
    var body: some View {
        if DeviceType.isMac {
            copyDestinationDirectoryPathButton
        } else {
            openDestinationDirectoryButton
        }
    }
    
    var copyDestinationDirectoryPathButton: some View {
        Button {
            do {
                UIPasteboard.general.string = try URL.defaultDestinationDirectory.path
            } catch {
                logger.fault("Can't get destination directory due to \(error)")
            }
        } label: {
            Label("Copy path to the folder containing received files",
                  systemImage: "doc.on.clipboard")
        }
    }
    
    var openDestinationDirectoryButton: some View {
        Button {
            let folderURL: URL
            do {
                folderURL = try .defaultDestinationDirectory
            } catch {
                logger.fault("Can't get destination directory due to \(error)")
                return
            }
            guard var components = URLComponents(
                url: folderURL,
                resolvingAgainstBaseURL: false
            ) else {
                logger.fault("Can't get components from \(folderURL)")
                return
            }
            components.scheme = "shareddocuments"
            guard let openInFilesURL = components.url else {
                logger.fault("Failed to assemble URL from \(components)")
                return
            }
            openURL(openInFilesURL)
        } label: {
            Label("Manage received files in the Files app",
                  systemImage: "tray.full")
        }
    }
}

struct OpenDocumentsFolderInFilesButton_Previews: PreviewProvider {
    static var previews: some View {
        OpenReceivedDocumentsFolderButton()
    }
}
