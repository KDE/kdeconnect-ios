//
//  DeviceData.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-06-17.
//

import Foundation
import Combine
import UniformTypeIdentifiers
import SwiftUI
import UIKit

class SelfDeviceData: ObservableObject {
    @Published var deviceName: String {
        didSet {
            UserDefaults.standard.set(deviceName, forKey: "deviceName")
        }
    }
    
    @Published var chosenTheme: String {
        didSet {
            UserDefaults.standard.set(chosenTheme, forKey: "chosenTheme")
        }
    }
    
    @Published var directIPs: [String] {
        didSet {
            UserDefaults.standard.set(directIPs, forKey: "directIPs")
        }
    }
    
    init() {
        self.deviceName = UserDefaults.standard.string(forKey: "deviceName") ?? UIDevice.current.name
        self.chosenTheme = UserDefaults.standard.string(forKey: "chosenTheme") ?? "System Default"
        self.directIPs = UserDefaults.standard.stringArray(forKey: "directIPs") ?? []
    }
}

// The host's SHA256 hash, calculated upon launch so we don't have to calculated it every single time
var hostSHA256Hash: String = "ERROR"

// Dictionary for app theme management
let appThemes: [String : ColorScheme] = ["Light":.light, "Dark":.dark]

// Array of all UTTypes, used by .fileImporter() to allow importing of all file types
let allUTTypes: [UTType] = [.aiff, .aliasFile, .appleArchive, .appleProtectedMPEG4Audio,
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
                            .xmlPropertyList, .xpcService, .yaml, .zip]
