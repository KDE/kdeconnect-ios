//
//  SettingsAboutView.swift
//  KDE Connect
//
//  Created by Ruixuan Tu on 2022-01-16.
//

import UIKit
import SwiftUI

struct SettingsAboutView: View {
    @Environment(\.openURL) var openURL
    @EnvironmentObject var settings: SelfDeviceData

    let version: String = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    let build: String = Bundle.main.infoDictionary!["CFBundleVersion"] as! String

    struct Library: Decodable, Identifiable {
        let id: String
        let name: String
        let repo: String
        let license: String
        let licenseURL: String
    }

    let libraries: [Library] = {
        let assetPath = Bundle.main.path(forResource: "libs", ofType: "json")
        let asset = try! Data(contentsOf: URL(fileURLWithPath: assetPath!), options: .mappedIfSafe)
        let decoder = JSONDecoder()
        let libraries = try! decoder.decode([Library].self, from: asset)
        return libraries
    }()

    var body: some View {
        List {
            Section {
                VStack {
                    HStack {
                        Spacer(minLength: 0.0)
                        settings.appIcon.image_60x60
                            .accessibilityHidden(true)
                        Spacer(minLength: 8.0)
                        VStack {
                            if #available(iOS 15, *) {
                                Text("**KDE Connect** for iOS")
                            } else {
                                HStack(spacing: 0.0) {
                                    Text("KDE Connect")
                                        .bold()
                                    Text(" for iOS")
                                }
                            }
                            Text("Version: \(version) (\(build))")
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
                    Text("Currently maintained by \(try! AttributedString(markdown: getContributorListText(for: \.maintainers)))")
                    Text("Also written by \(try! AttributedString(markdown: getContributorListText(for: \.authors)))")
                } else {
                    Text(getContributorListAttributedTextWrapper(for: \.maintainers).string)
                        .opacity(0.0)
                        .accessibilityHidden(true)
                        .overlay(iOS14CompatibleTextView(getContributorListAttributedTextWrapper(for: \.maintainers)))
                    Text(getContributorListAttributedTextWrapper(for: \.authors).string)
                        .opacity(0.0)
                        .accessibilityHidden(true)
                        .overlay(iOS14CompatibleTextView(getContributorListAttributedTextWrapper(for: \.authors)))
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

    struct Contributor: Decodable {
        let name: String
        let kde: String
    }

    struct Contributors: Decodable {
        let maintainers: [Contributor]
        let authors: [Contributor]
    }

    func getContributorList(for category: KeyPath<Contributors, [Contributor]>) -> [Contributor] {
        // for maintainer of contributors.json: please keep the order by "name" of contributors
        let assetPath = Bundle.main.path(forResource: "contributors", ofType: "json")
        let asset = try! Data(contentsOf: URL(fileURLWithPath: assetPath!), options: .mappedIfSafe)
        let decoder = JSONDecoder()
        let json = try! decoder.decode(Contributors.self, from: asset)
        let contributors = json[keyPath: category]
        return contributors
    }

    func getContributorListText(for category: KeyPath<Contributors, [Contributor]>) -> String {
        let contributors = getContributorList(for: category)
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
    func getContributorListAttributedText(template: String, for category: KeyPath<Contributors, [Contributor]>) -> NSAttributedString {
        let contributors = getContributorList(for: category)
        let contributorNames = contributors.map {
            $0.name
        }
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: UIColor.label
        ]
        let contributorsJoinedString = ListFormatter.localizedString(byJoining: contributorNames)
        let contributorsListAttributedText = NSMutableAttributedString(string: String(format: template, contributorsJoinedString), attributes: textAttributes)
        // can be optimized to O(n) by a more complicated way
        // Swift String indices: https://docs.swift.org/swift-book/LanguageGuide/StringsAndCharacters.html#ID494
        for contributor in contributors {
            let linkAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.preferredFont(forTextStyle: .body),
                .foregroundColor: UIColor.link,
                .link: kdeInvent + contributor.kde
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
    func getContributorListAttributedTextWrapper(for category: KeyPath<Contributors, [Contributor]>) -> NSAttributedString {
        let template: String;
        switch category {
        case \.maintainers:
            template = NSLocalizedString("Currently maintained by %@", comment: "maintainer localized string")
        case \.authors:
            template = NSLocalizedString("Also written by %@", comment: "author localized string")
        default:
            fatalError("unexpected category")
        }
        return getContributorListAttributedText(template: template, for: category)
    }
}

struct SettingsAboutView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsAboutView()
            .environmentObject(selfDeviceData)
    }
}
