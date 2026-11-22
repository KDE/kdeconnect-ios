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
        Feature(Text("Clipboard: Push & Receive Text")),
        Feature(Text("Share: Send File")),
        Feature(Text("Share: Receive File, Text, and URL")),
        Feature(Text("Presentation remote")),
        Feature(Text("Remote Mouse and Keyboard Control")),
        Feature(Text("Run Command")),
        Feature(Text("Battery Status")),
    ]
    private let inProgressFeatures: [Feature] = [
    ]
    private let unsupportedFeatures: [Feature] = [
        Feature(Text("Background Activity"),
                details: Text("Currently, the app must stay in the foreground to work properly")
                            .fontWeight(.bold)
                            .italic()
                            .underline()
                            .foregroundColor(.red)),
        Feature(Text("Share: Send Text & URL"),
                details: Text("Through the system share sheet")),
        Feature(Text("Contacts")),
        Feature(Text("Connectivity Report")),
        Feature(Text("Remote Browse Files")),
        Feature(Text("Control Multimedia Players")),
        Feature(Text("Change System Volume")),
        Feature(Text("Notifications sync"),
                details: Text("Maybe with Apple Notification Center Service (ACNS)")),
        Feature(Text("Telephony: SMS/Call Sync"),
                details: Text("This is likely not possible to implement on iOS")),
    ]
    
    var body: some View {
        List {
            Text("As an open source project, we believe it is important to be transparent about our current and future plans to bring KDE Connect iOS into line with all other platforms.")
            
            supportedFeaturesSection
                .headerProminence(.increased)
            inProgressFeaturesSection
                .headerProminence(.increased)
            unsupportedFeaturesSection
                .headerProminence(.increased)
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
                        Image(systemName: "checkmark.circle.trianglebadge.exclamationmark")
                            .renderingMode(.original)
                            .foregroundColor(.green)
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
                    Image(systemName: "hammer.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        } header: {
            Text("In progress")
        } footer: {
            Link(destination: URL(string: "https://invent.kde.org/network/kdeconnect-ios/-/merge_requests")!) {
                Text("Check out the merge requests")
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
                Text("Contribute to KDE Connect")
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
