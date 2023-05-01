/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  SetupForUITests.swift
//  KDE Connect
//
//  Created by Apollo Zhu on 2/25/22.
//

#if DEBUG
enum UIPreview {
    enum DeviceID: String {
        case iPhone
        case iPad
        case android
        case macBook
        case desktop
    }
    
    // When choosing device names, think The practice of inclusive design
    // https://developer.apple.com/videos/play/wwdc2021/10275/
    static func setupFakeDevices() {
        let macBook = makeDevice(
            id: .macBook, type: .laptop,
            name: NSLocalizedString("McIntosh",
                                    comment: "Name of a kind of apple, used as App Store screenshot device name of a MacBook")
        )
        let macBookBattery = macBook.plugins[.batteryRequest] as! Battery
        macBookBattery.remoteChargeLevel = 100
        let macBookRunCommand = macBook.plugins[.runCommand] as! RunCommand
        macBookRunCommand.commandEntries = [
            CommandEntry(name: NSLocalizedString("Hello World",
                                                 comment: "The first thing you print when starting to learn programming, used in App Store screenshot as the name of a command that can be executed on the remote device"),
                         command: "echo Hello World", key: "test"),
        ]
        backgroundService.devices = Dictionary(uniqueKeysWithValues: [
            macBook,
            makeDevice(
                id: .iPad, type: .tablet,
                name: NSLocalizedString("Malus",
                                        comment: "Name of a kind of apple, used as App Store screenshot device name of an iPad")
            ),
            makeDevice(
                id: .iPhone, type: .phone,
                name: NSLocalizedString("Fuji",
                                        comment: "Name of a kind of apple, used as App Store screenshot device name of an iPhone")
            ),
            makeDevice(
                id: .android, type: .tablet,
                name: NSLocalizedString("Marshmallow",
                                        comment: "Name of a kind of candy, used as App Store screenshot device name of a Android tablet")
            ),
            makeDevice(
                id: .desktop, type: .desktop,
                name: NSLocalizedString("Plasma",
                                        comment: "Name of KDE's graphical workspaces environment, used as App Store screenshot device name of a desktop device")
            ),
        ].map { ($0._id, $0) })
        
        setupFileTransfers()
        
        connectedDevicesViewModel.connectedDevices = devicesDictionary(for: .macBook, .desktop)
        connectedDevicesViewModel.visibleDevices = devicesDictionary(for: .iPad)
        connectedDevicesViewModel.savedDevices = devicesDictionary(for: .iPhone, .android)
    }
    
    static let allCapabilities = NetworkPackage.allPackageTypes.map { $0.rawValue }
    
    static func makeDevice(id: DeviceID, type: DeviceType, name: String) -> Device {
        return Device(
            id: id.rawValue, type: type, name: name,
            incomingCapabilities: allCapabilities,
            outgoingCapabilities: allCapabilities,
            protocolVersion: 0,
            deviceDelegate: backgroundService
        )!
    }
    
    static func devicesDictionary(for ids: DeviceID...) -> [String: String] {
        Dictionary(uniqueKeysWithValues: ids.map { ($0.rawValue, backgroundService.devices[$0.rawValue]!._name) })
    }
}
#endif
