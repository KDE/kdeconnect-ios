//
//  SettingsAboutView.swift
//  KDE Connect
//
//  Created by Ruixuan Tu on 2022-01-16.
//

#if !os(macOS)

import UIKit
import SwiftUI

struct SettingsAboutView: View {
    @Environment(\.openURL) var openURL
    @EnvironmentObject private var kdeConnectSettings: KdeConnectSettings

    // swiftlint:disable force_cast force_unwrapping
    // These values missing as written is a serious programmer error
    let version: String = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    let build: String = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
    // swiftlint:enable force_cast force_unwrapping

    struct Library: Decodable, Identifiable {
        let id: String
        let name: String
        let repo: String
        let license: String
        let licenseURL: String
    }

    let libraries: [Library] = {
        let assetPath = Bundle.main.path(forResource: "libs", ofType: "json")
        // The asset file is static and should be in the correct location.
        // swiftlint:disable:next force_try force_unwrapping
        let asset = try! Data(contentsOf: URL(fileURLWithPath: assetPath!), options: .mappedIfSafe)
        let decoder = JSONDecoder()
        // The JSON file is static and should be in the correct format.
        // swiftlint:disable:next force_try
        let libraries = try! decoder.decode([Library].self, from: asset)
        return libraries
    }()

    var body: some View {
        List {
            Section {
                VStack {
                    HStack {
                        Spacer(minLength: 0.0)
                        kdeConnectSettings.appIcon.image60x60
                            .accessibilityHidden(true)
                        Spacer(minLength: 8.0)
                        VStack {
                            if #available(iOS 15, *) {
                                Text("**KDE Connect** for iOS")
                            } else {
                                Text("\(Text("KDE Connect").bold()) for iOS")
                            }
                            Label {
                                Text("Version: \(version) (\(build))")
                            } icon: {
                                if kdeConnectSettings.isDebugging {
                                    Image(systemName: "hammer.fill")
                                        .foregroundColor(.primary)
                                }
                            }
                            .accessibilityValue(kdeConnectSettings.isDebugging ? Text("Debug mode") : Text(""))
                            .onTapGesture(count: 10) {
                                withAnimation {
                                    kdeConnectSettings.isDebugging = true
                                }
                            }
                            .accessibilityAddTraits(kdeConnectSettings.isDebugging ? [] : .isButton)
                            .accessibilityHint(kdeConnectSettings.isDebugging ? Text("") : Text("Double tap to activate debug mode"))
                            .accessibilityAction {
                                withAnimation {
                                    kdeConnectSettings.isDebugging = true
                                }
                            }
                            Text("© KDE Community & contributors")
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        Spacer(minLength: 0.0)
                    }
                    Text("Multi-platform app that allows your devices to communicate (e.g., your phone and your computer)")
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Section(header: Text("Actions")) {
                // tried LazyHGrid but not flexible enough, enlarged text would break the layout
                Link(destination: URL(string: "https://bugs.kde.org/enter_bug.cgi?product=kdeconnect&component=ios-application")!) {
                    Label("Report Bug", systemImage: "ladybug")
                }
                Link(destination: URL(string: "https://kde.org/community/donations")!) {
                    Label("Donate", systemImage: "dollarsign.square")
                }
                Link(destination: URL(string: "https://invent.kde.org/network/kdeconnect-ios")!) {
                    if #available(iOS 15, *) {
                        Label("Source Code", systemImage: "chevron.left.forwardslash.chevron.right")
                    } else {
                        Label("Source Code", systemImage: "chevron.left.slash.chevron.right")
                    }
                }
                Link(destination: URL(string: "https://invent.kde.org/network/kdeconnect-ios/-/blob/master/License.md")!) {
                    Label("License", systemImage: "doc.plaintext")
                }
                Link(destination: URL(string: "https://userbase.kde.org/KDEConnect")!) {
                    Label("Wiki & User Manual", systemImage: "books.vertical")
                }
                Link(destination: URL(string: "https://kdeconnect.kde.org")!) {
                    Label("Website", systemImage: "globe")
                }
            }
            .foregroundColor(.primary)

            Section(header: Text("Contributors")) {
                if #available(iOS 15, *) {
                    // markdown is actually static text and should always succeed in conversion
                    // swiftlint:disable force_try
                    Text("Currently maintained by \(try! AttributedString(markdown: getContributorListText(for: .maintainers)))")
                    Text("Also written by \(try! AttributedString(markdown: getContributorListText(for: .authors)))")
                    // swiftlint:enable force_try
                } else {
                    Text(getContributorListAttributedTextWrapper(for: .maintainers).string)
                        .opacity(0.0)
                        .accessibilityHidden(true)
                        .overlay(iOS14CompatibleTextView(getContributorListAttributedTextWrapper(for: .maintainers)))
                    Text(getContributorListAttributedTextWrapper(for: .authors).string)
                        .opacity(0.0)
                        .accessibilityHidden(true)
                        .overlay(iOS14CompatibleTextView(getContributorListAttributedTextWrapper(for: .authors)))
                }
            }

            Section(header: Text("Third-Party Libraries")) {
                ForEach(libraries) { library in
                    // for maintainer of libs.json: please keep the order by by "ID", i.e., project name
                    HStack {
                        Button(library.name) {
                            openURL(URL(string: library.repo)!)
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.primary)
                        Spacer()
                        Button(library.license) {
                            openURL(URL(string: library.licenseURL)!)
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("About")
    }

    let kdeInvent = "https://invent.kde.org/"
    
    func getContributorListText(for category: Contributors) -> String {
        let contributors = category.identities
        let list = contributors.map {
            "[\($0.name)](\(kdeInvent + $0.kde))"
        }
        return ListFormatter.localizedString(byJoining: list)
    }

    @available(iOS, deprecated: 15, message:
            """
            Manually generated attributed text should only be used for backwards compatibility with iOS 14.
            iOS 15 should follow the new convention of using Text() supporting Markdown attributes.
            """
    )
    func getContributorListAttributedText(template: String, for category: Contributors) -> NSAttributedString {
        let contributors = category.identities
        let contributorNames = contributors.map {
            $0.name
        }
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: UIColor.label,
        ]
        let contributorsJoinedString = ListFormatter.localizedString(byJoining: contributorNames)
        let contributorsListAttributedText = NSMutableAttributedString(string: String(format: template, contributorsJoinedString), attributes: textAttributes)
        // can be optimized to O(n) by a more complicated way
        // Swift String indices: https://docs.swift.org/swift-book/LanguageGuide/StringsAndCharacters.html#ID494
        for contributor in contributors {
            let linkAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.preferredFont(forTextStyle: .body),
                .foregroundColor: UIColor.link,
                .link: kdeInvent + contributor.kde,
            ]
            let range = (contributorsListAttributedText.string as NSString).range(of: contributor.name)
            contributorsListAttributedText.setAttributes(linkAttributes, range: range)
        }
        return contributorsListAttributedText
    }

    @available(iOS, deprecated: 15, message:
            """
            Manually generated attributed text should only be used for backwards compatibility with iOS 14.
            iOS 15 should follow the new convention of using Text() supporting Markdown attributes.
            """
    )
    func getContributorListAttributedTextWrapper(for category: Contributors) -> NSAttributedString {
        let template: String
        switch category {
        case .maintainers:
            template = NSLocalizedString("Currently maintained by %@", comment: "maintainer localized string")
        case .authors:
            template = NSLocalizedString("Also written by %@", comment: "author localized string")
        }
        return getContributorListAttributedText(template: template, for: category)
    }
}

struct SettingsAboutView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsAboutView()
            .environmentObject(KdeConnectSettings.shared)
    }
}

#endif
