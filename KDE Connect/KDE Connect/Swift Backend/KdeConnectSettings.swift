/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  DeviceData.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-06-17.
//

import UniformTypeIdentifiers
import SwiftUI

import os.log
@objc
class KdeConnectSettings: NSObject, ObservableObject {
    @objc
    static let shared = KdeConnectSettings()

    static let CurrentProtocolVersion = 8
    
    // FIXME: actually read what plugins are available
    static let IncomingCapabilities: [NetworkPacket.`Type`] = [
        .ping,
        .share,
        .shareRequestUpdate,
        .findMyPhoneRequest,
        .batteryRequest,
        .battery,
        .clipboard,
        .clipboardConnect,
        .runCommand,
    ]
    static let OutgoingCapabilities: [NetworkPacket.`Type`] = [
        .ping,
        .share,
        .shareRequestUpdate,
        .findMyPhoneRequest,
        .batteryRequest,
        .battery,
        .clipboard,
        .clipboardConnect,
        .mousePadRequest,
        .presenter,
        .runCommandRequest,
    ]
    
    private static var cachedUuid: String?

    @objc
    static func getUUID() -> String {
        if cachedUuid == nil {
            let group = "5433B4KXM8.org.kde.kdeconnect"
            let wrapper = KeychainItemWrapper(identifier: "org.kde.kdeconnect-ios", accessGroup: group)!
            if let savedUUID = wrapper.object(forKey: kSecValueData as String) as? String, !savedUUID.isEmpty {
                cachedUuid = savedUUID
            } else {
#if !os(macOS)
                // identifierForVendor can be nil if called when a device has restarted but not been unlocked yet
                if let identifierForVendor = UIDevice.current.identifierForVendor {
                    cachedUuid = identifierForVendor.uuidString.replacingOccurrences(of: "-", with: "_").lowercased()
                    wrapper.setObject(cachedUuid, forKey: kSecValueData as String)
                }
#else
                let identifierForVendor = NetworkPacket.getMacUUID()
                cachedUuid = identifierForVendor.replacingOccurrences(of: "-", with: "_").lowercased()
                wrapper.setObject(cachedUuid, forKey: kSecValueData as String)
#endif
            }
            let logger = OSLog(subsystem: NSStringFromClass(self), category: "UUIDManager")
            os_log("Get UUID %{mask.hash}@", log: logger, type: .info, cachedUuid ?? "")
        }
        return cachedUuid!
    }
    
    @Published var deviceName: String {
        didSet {
            UserDefaults.standard.set(DeviceInfo.filterDeviceName(name: deviceName), forKey: "deviceName")
        }
    }
    
    @Published var chosenTheme: ColorScheme? {
        didSet {
            UserDefaults.standard.set(chosenTheme?.rawValue, forKey: "chosenTheme")
        }
    }
    
    @Published var appIcon: AppIcon {
        didSet {
            UserDefaults.standard.set(appIcon.rawValue, forKey: "appIcon")
        }
    }
    
    @Published var directIPs: [String] {
        didSet {
            UserDefaults.standard.set(directIPs, forKey: "directIPs")
        }
    }
    
    @Published var savePhotosToPhotosLibrary: Bool {
        didSet {
            UserDefaults.standard.set(savePhotosToPhotosLibrary,
                                      forKey: "savePhotosToPhotosLibrary")
        }
    }
    
    @Published var saveVideosToPhotosLibrary: Bool {
        didSet {
            UserDefaults.standard.set(saveVideosToPhotosLibrary,
                                      forKey: "saveVideosToPhotosLibrary")
        }
    }
    
    @Published var disableUdpBroadcastDiscovery: Bool {
        didSet {
            UserDefaults.standard.set(disableUdpBroadcastDiscovery,
                                      forKey: "disableUdpBroadcastDiscovery")
        }
    }
    
    /// Intentionally not persisted
    @Published var isDebugging: Bool
    @objc
    @Published var isDebuggingDiscovery: Bool
    @objc
    @Published var isDebuggingNetworkPacket: Bool
    
    private override init() {
        UserDefaults.standard.register(defaults: [
            "savePhotosToPhotosLibrary": !DeviceType.isMac,
            "saveVideosToPhotosLibrary": !DeviceType.isMac,
        ])
#if !os(macOS)
        let fallbackName = UIDevice.current.name
#else
        let fallbackName = Host.current().localizedName ?? "Unknown Hostname"
#endif
        self.deviceName = UserDefaults.standard.string(forKey: "deviceName") ?? fallbackName
        self.chosenTheme = UserDefaults.standard.string(forKey: "chosenTheme").flatMap(ColorScheme.init)
        self.directIPs = UserDefaults.standard.stringArray(forKey: "directIPs") ?? []
        self.disableUdpBroadcastDiscovery = UserDefaults.standard.bool(forKey: "disableUdpBroadcastDiscovery")
        self.appIcon = AppIcon(rawValue: UserDefaults.standard.string(forKey: "appIcon")) ?? .default
        self.savePhotosToPhotosLibrary = UserDefaults.standard.bool(forKey: "savePhotosToPhotosLibrary")
        self.saveVideosToPhotosLibrary = UserDefaults.standard.bool(forKey: "saveVideosToPhotosLibrary")
        #if DEBUG
        let launchArguments = Set(ProcessInfo.processInfo.arguments)
        self.isDebugging = launchArguments.contains("isDebugging")
        self.isDebuggingDiscovery = launchArguments.contains("isDebuggingDiscovery")
        self.isDebuggingNetworkPacket = launchArguments.contains("isDebuggingNetworkPacket")
        #else
        self.isDebugging = false
        self.isDebuggingDiscovery = false
        self.isDebuggingNetworkPacket = false
        #endif
        super.init()
    }
}

extension ColorScheme: RawRepresentable {
    public typealias RawValue = String
    
    public init?(rawValue: String) {
        switch rawValue {
        case "Light": self = .light
        case "Dark": self = .dark
        default: return nil
        }
    }
    
    public var rawValue: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        @unknown default: return "Unknown"
        }
    }
}

extension Optional where Wrapped == ColorScheme {
    var text: Text {
        switch self {
        case .none:
            return Text("System Default")
        case .some(let scheme):
            switch scheme {
            case .light: return Text("Light")
            case .dark: return Text("Dark")
            @unknown default: return Text("Unknown Theme")
            }
        }
    }
}

extension Optional: CaseIterable where Wrapped: CaseIterable {
    public static var allCases: [Optional<Wrapped>] {
        return [nil] + Wrapped.allCases.map(Self.init)
    }
}

// The host's SHA256 hash, calculated upon launch so we don't have to calculated it every single time
var hostSHA256Hash: String = "ERROR"

// Array of all UTTypes, used by .fileImporter() to allow importing of all file types
let allUTTypes: [UTType] = [
    .aiff, .aliasFile, .appleArchive, .appleProtectedMPEG4Audio,
    .appleProtectedMPEG4Video, .appleScript, .application,
    .applicationBundle, .applicationExtension, .arReferenceObject,
    .archive, .assemblyLanguageSource, .audio, .audiovisualContent,
    .avi, .binaryPropertyList, .bmp, .bookmark, .bundle, .bz2,
    .cHeader, .cPlusPlusHeader, .cPlusPlusSource, .cSource,
    .calendarEvent, .commaSeparatedText, .compositeContent,
    .contact, .content, .data, .database, .delimitedText, .directory,
    .diskImage, .emailMessage, .epub, .exe, .executable, .fileURL,
    .flatRTFD, .folder, .font, .framework, .gif, .gzip, .heic, .html,
    .icns, .ico, .image, .internetLocation, .internetShortcut, .item,
    .javaScript, .jpeg, .json, .livePhoto, .log, .m3uPlaylist,
    /**.makefile (iOS 15 beta),**/ .message, .midi, .mountPoint, .movie, .mp3,
    .mpeg, .mpeg2TransportStream, .mpeg2Video, .mpeg4Audio,
    .mpeg4Movie, .objectiveCPlusPlusSource, .objectiveCSource,
    .osaScript, .osaScriptBundle, .package, .pdf, .perlScript,
    .phpScript, .pkcs12, .plainText, .playlist, .pluginBundle, .png,
    .presentation, .propertyList, .pythonScript, .quickLookGenerator,
    .quickTimeMovie, .rawImage, .realityFile, .resolvable, .rtf, .rtfd,
    .rubyScript, .sceneKitScene, .script, .shellScript, .sourceCode,
    .spotlightImporter, .spreadsheet, .svg, .swiftSource,
    .symbolicLink, .systemPreferencesPane, .tabSeparatedText, .text,
    .threeDContent, .tiff, .toDoItem, .unixExecutable, .url,
    .urlBookmarkData, .usd, .usdz, .utf16ExternalPlainText,
    .utf16PlainText, .utf8PlainText, .utf8TabSeparatedText, .vCard,
    .video, .volume, .wav, .webArchive, .webP, .x509Certificate, .xml,
    .xmlPropertyList, .xpcService, .yaml, .zip,
]
