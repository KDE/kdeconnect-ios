/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 *                         2022 Apollo Zhu <public-apollonian@outlook.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  FeaturesList.swift
//  KDE Connect
//
//  Created by Apollo Zhu on 2/22/22.
//

import SwiftUI

struct FeaturesList: View {
    private let supportedFeatures: [Feature] = [
        Feature(Text("Discovery & Pairing"),
                details: Text("May not work with KDE Connect for Windows")),
        Feature(Text("Ping")),
        Feature(Text("Find My Device")),
        Feature(Text("Battery Status")),
        Feature(Text("Clipboard: Push & Receive Text")),
        Feature(Text("Share: Send File"),
                details: Text("Integration with the system share sheet is in development")),
        Feature(Text("Share: Receive File, Text, and URL")),
        Feature(Text("Presenter: Control Remote")),
        Feature(Text("Mouse: Control Remote")),
        Feature(Text("Keyboard: Control Remote")),
        Feature(Text("Run Command: Request")),
    ]
    private let inProgressFeatures: [Feature] = [
        Feature(Text("Share: Send Text & URL"),
                details: Text("Through the system share sheet")),
        Feature(Text("Trusted Networks")),
        Feature(Text("Internationalization & Localization")),
    ]
    private let unsupportedFeatures: [Feature] = [
        Feature(Text("Background Activity"),
                details: Text("Currently, the app must stay in the foreground to work properly")
                            .fontWeight(.bold)
                            .italic()
                            .underline()
                            .foregroundColor(.red)),
        Feature(Text("Clipboard: Sync"),
                details: Text("Maybe through URL Scheme and integration with Siri Shortcuts")),
        Feature(Text("Contacts")),
        Feature(Text("Connectivity Report")),
        Feature(Text("SFTP: Access Remote & Initiate File Server")),
        Feature(Text("Lock Screen: Control Remote")),
        Feature(Text("Screensaver: Inhibit Remote")),
        Feature(Text("Take Photo: Respond")),
        Feature(Text("Plasma Bigscreen")),
        Feature(Text("MPRIS: Control Remote Media & Respond")),
        Feature(Text("System Volume: Control Remote & Respond")),
        Feature(Text("Run Command: Respond"),
                // https://developer.apple.com/documentation/sirikit/offering_actions_in_the_shortcuts_app
                // https://support.apple.com/guide/shortcuts/run-a-shortcut-from-a-url-apd624386f42/ios
                details: Text("Integration with Siri Shortcuts")),
        Feature(Text("Notification: Receive from Others")),
        Feature(Text("Notification: Retrieve by Others"),
                details: Text("Maybe with Apple Notification Center Service (ACNS)")),
        Feature(Text("Telephony: SMS/Call Sync"),
                details: Text("This is likely not possible to implement on iOS")),
    ]
    
    var body: some View {
        List {
            Text("As an open source project, we believe it is important to be transparent about our current and future plans to bring KDE Connect iOS into line with all other platforms.")
            
            if #available(iOS 15, *) {
                supportedFeaturesSection
                    .headerProminence(.increased)
                inProgressFeaturesSection
                    .headerProminence(.increased)
                unsupportedFeaturesSection
                    .headerProminence(.increased)
            } else {
                supportedFeaturesSection
                inProgressFeaturesSection
                unsupportedFeaturesSection
            }
        }
        .navigationTitle("Features")
    }
    
    private var supportedFeaturesSection: some View {
        Section {
            ForEach(supportedFeatures) { feature in
                Label {
                    Feature.DefaultView(feature: feature)
                } icon: {
                    if feature.details == nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        if #available(iOS 15, *) {
                            Image(systemName: "checkmark.circle.trianglebadge.exclamationmark")
                                .renderingMode(.original)
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
        } header: {
            Text("Supported")
        } footer: {
            Text("These should work with little to no issues")
        }
    }
    
    private var inProgressFeaturesSection: some View {
        Section {
            ForEach(inProgressFeatures) { feature in
                Label {
                    Feature.DefaultView(feature: feature)
                } icon: {
                    if #available(iOS 15, *) {
                        Image(systemName: "hammer.circle.fill")
                            .foregroundColor(.blue)
                    } else {
                        Image(systemName: "hammer.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
        } header: {
            Text("In progress")
        } footer: {
            Link(destination: URL(string: "https://invent.kde.org/network/kdeconnect-ios/-/merge_requests")!) {
                if #available(iOS 15, *) {
                    Text("Check out the merge requests")
                } else {
                    Text("Check out the merge requests")
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
    
    private var unsupportedFeaturesSection: some View {
        Section {
            ForEach(unsupportedFeatures) { feature in
                Label {
                    Feature.DefaultView(feature: feature)
                } icon: {
                    Image(systemName: "circle.dashed")
                        .foregroundColor(.primary)
                }
            }
        } header: {
            Text("Not yet implemented")
        } footer: {
            Link(destination: URL(string: "https://invent.kde.org/network/kdeconnect-ios")!) {
                if #available(iOS 15, *) {
                    Text("Contribute to KDE Connect")
                } else {
                    Text("Contribute to KDE Connect")
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
    
    private struct Feature: Identifiable {
        let id = UUID()
        let text: Text
        let details: Text?
        
        init(_ text: Text, details: Text? = nil) {
            self.text = text
            self.details = details
        }
        
        fileprivate struct DefaultView: View {
            let feature: Feature
            
            var body: some View {
                if let details = feature.details {
                    VStack(alignment: .leading) {
                        feature.text
                        details
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    feature.text
                }
            }
        }
    }
}

struct FeaturesList_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FeaturesList()
        }
    }
}
