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
func setupForUITests() {
    let allCapabilities = NetworkPackage.allPackageTypes.map { $0.rawValue }
    let macBook = Device(
        id: "MacBook", type: .laptop,
        name: NSLocalizedString("McIntosh",
                                comment: "Name of a kind of apple, used as App Store screenshot device name of a MacBook"),
        incomingCapabilities: allCapabilities,
        outgoingCapabilities: allCapabilities,
        protocolVersion: 0,
        deviceDelegate: backgroundService
    )!
    let macBookBattery = macBook.plugins[.batteryRequest] as! Battery
    macBookBattery.remoteChargeLevel = 100
    let macBookRunCommand = macBook.plugins[.runCommand] as! RunCommand
    macBookRunCommand.commandEntries = [
        CommandEntry(name: "Hello World", command: "echo Hello World", key: "test")
    ]
    backgroundService.devices = Dictionary(uniqueKeysWithValues: [
        macBook,
        Device(
            id: "iPad", type: .tablet,
            name: NSLocalizedString("Malus",
                                    comment: "Name of a kind of apple, used as App Store screenshot device name of an iPad"),
            incomingCapabilities: [],
            outgoingCapabilities: [],
            protocolVersion: 0,
            deviceDelegate: backgroundService
        ),
        Device(
            id: "iPhone", type: .phone,
            name: NSLocalizedString("Fuji",
                                    comment: "Name of a kind of apple, used as App Store screenshot device name of an iPhone"),
            incomingCapabilities: [],
            outgoingCapabilities: [],
            protocolVersion: 0,
            deviceDelegate: backgroundService
        ),
        Device(
            id: "Android", type: .tablet,
            name: NSLocalizedString("Marshmallow",
                                    comment: "Name of a kind of candy, used as App Store screenshot device name of a Android tablet"),
            incomingCapabilities: [],
            outgoingCapabilities: [],
            protocolVersion: 0,
            deviceDelegate: backgroundService
        ),
        Device(
            id: "Desktop", type: .desktop,
            name: NSLocalizedString("Plasma",
                                    comment: "Name of KDE's graphical workspaces environment, used as App Store screenshot device name of a desktop device"),
            incomingCapabilities: [],
            outgoingCapabilities: [],
            protocolVersion: 0,
            deviceDelegate: backgroundService
        ),
    ].map { ($0._id, $0) })
    func devicesDictionary(for ids: String...) -> [String: String] {
        Dictionary(uniqueKeysWithValues: ids.map { ($0, backgroundService.devices[$0]!._name) })
    }
    connectedDevicesViewModel.connectedDevices = devicesDictionary(for: macBook._id)
    connectedDevicesViewModel.visibleDevices = devicesDictionary(for: "Desktop", "iPad")
    connectedDevicesViewModel.savedDevices = devicesDictionary(for: "iPhone", "Android")
}
#endif
