/*
 * SPDX-FileCopyrightText: 2023 Apollo Zhu <public-apollonian@outlook.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

//
//  FilesTab.swift
//  KDE Connect
//
//  Created by Apollo Zhu on 4/12/23.
//

import SwiftUI
import Photos

struct FilesTab: View {
    @EnvironmentObject private var selfDeviceData: SelfDeviceData
    
    @State private var photoLibraryAuthorizationStatus: PHAuthorizationStatus = .notDetermined
    @State private var category: Category = .receiving
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.openURL) private var openURL
    
    private let logger = Logger()
    
    enum Category: Hashable {
        case receiving
        case sending
        case errored
    }
    
    var body: some View {
        NavigationView {
            list
                .toolbar {
                    if horizontalSizeClass != .regular {
                        categoryPicker
                    }
                }
                .navigationTitle("File Transfers")
                .onAppear {
                    updateAuthorizationStatus()
                }
                .onReceive(NotificationCenter.default
                    .publisher(for: .failedToAddToPhotosLibrary, object: nil)
                    .receive(on: RunLoop.main)
                ) { _ in
                    updateAuthorizationStatus()
                }
            
            List {
                FileTransferStatusOverview(category: category)
                
                if #available(iOS 15, *) {
                    // To keep the background color consistent
                    // when there are no transfers going on...
                    Spacer()
                        .listRowBackground(Color.clear)
                } // no workaround needed for iOS 14
            }
            .toolbar {
                if horizontalSizeClass == .regular {
                    categoryPicker
                }
            }
            .navigationTitle("Status")
        }
    }
    
    @ViewBuilder
    var list: some View {
        switch horizontalSizeClass {
        case .regular:
            List {
                additions
            }
        case .compact, nil:
            fullList
        @unknown default:
            fullList
        }
    }
    
    var fullList: some View {
        List {
            additions
            
            FileTransferStatusOverview(category: category)
        }
        .listStyle(.insetGrouped)
    }
    
    var categoryPicker: some View {
        Picker("Category", selection: $category) {
            Text("Receiving")
                .tag(Category.receiving)
            Text("Sending")
                .tag(Category.sending)
            Text("Errored")
                .tag(Category.errored)
        }
        .pickerStyle(.segmented)
    }
    
    @ViewBuilder
    var additions: some View {
        saveToPhotosPreferences
        
        OpenReceivedDocumentsFolderButton()
    }
    
    @ViewBuilder
    var saveToPhotosPreferences: some View {
        switch photoLibraryAuthorizationStatus {
        case .restricted:
            Label("Received photos and videos will be saved to the Files app because you can't grant us access to your photo library.",
                  systemImage: "info.circle")
        case .denied:
            Button {
                guard let url = URL(string: UIApplication.openSettingsURLString) else {
                    logger.fault("Invalid settings URL \(UIApplication.openSettingsURLString)")
                    return
                }
                openURL(url)
            } label: {
                Label("Authorize Photos access using the Settings app to save received photos and videos to your photo library",
                      systemImage: "arrow.up.forward.square")
                .font(.body.bold())
            }
        case .notDetermined, .authorized, .limited:
            saveToPhotosToggles
        @unknown default:
            saveToPhotosToggles
        }
    }
    
    @ViewBuilder
    var saveToPhotosToggles: some View {
        Toggle(isOn: $selfDeviceData.savePhotosToPhotosLibrary) {
            Label("Save photos to the photo library",
                  systemImage: "photo.on.rectangle.angled")
        }
        
        Toggle(isOn: $selfDeviceData.saveVideosToPhotosLibrary) {
            Label("Save videos to the photo library",
                  systemImage: "film")
        }
    }
    
    func updateAuthorizationStatus() {
        photoLibraryAuthorizationStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
    }
}

#if DEBUG
struct FilesTab_Previews: PreviewProvider {
    static var previews: some View {
        UIPreview.setupFakeDevices()

        return Group {
            previewLayouts
                .environmentObject(SelfDeviceData.shared)
                .environmentObject(connectedDevicesViewModel)
            
            // When there are no transfers
            previewLayouts
                .environmentObject(SelfDeviceData.shared)
                .environmentObject(ConnectedDevicesViewModel())
        }
    }
    
    @ViewBuilder
    static var previewLayouts: some View {
        FilesTab()
            .introspectSplitViewController { splitViewController in
                splitViewController.preferredSplitBehavior = .tile
                splitViewController.preferredDisplayMode = .oneBesideSecondary
            }
            .previewDevice("iPhone 14 Pro Max")
            .previewDisplayName("Compact")
        
        FilesTab()
            .introspectSplitViewController { splitViewController in
                splitViewController.preferredSplitBehavior = .tile
                splitViewController.preferredDisplayMode = .oneBesideSecondary
            }
            .previewDevice("iPad Pro (12.9-inch) (6th generation)")
            .previewDisplayName("Regular")
    }
}
#endif
