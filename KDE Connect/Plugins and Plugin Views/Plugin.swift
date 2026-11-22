/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 *                         2023 Apollo Zhu <public-apollonian@outlook.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  Plugin.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-08-11.
//

import Foundation

@objc protocol Plugin: NSObjectProtocol {
    @objc func onDevicePacketReceived(np: NetworkPacket)
    @objc optional func onPacket(_ np: NetworkPacket,
                                 sentWithPacketTag packetTag: Int)
    @objc optional func onPacket(_ np: NetworkPacket,
                                 sendWithPacketTag packetTag: Int,
                                 failedWithError error: Error)
    
    // MARK: payload related
    @objc optional func onSendingPayload(_ payload: FileTransferItem)
    @objc optional func willReceivePayload(_ payload: FileTransferItem,
                                           totalNumOfFilesToReceive: Int)
    @objc optional func onReceivingPayload(_ payload: FileTransferItem)
    @objc optional func onReceivingPayload(_ payload: FileTransferItem,
                                           failedWithError error: Error)
}

typealias ObservablePlugin = Plugin & ObservableObject

/// Like Android's PluginFactory: each plugin declares the packet types it can receive and send,
/// and it is loaded for a device only if the capabilities of that device match some of them.
@objc class PluginFactory: NSObject {
    private struct PluginInfo {
        let supportedPacketTypes: Set<NetworkPacket.`Type`>
        let outgoingPacketTypes: Set<NetworkPacket.`Type`>
        let create: (Device) -> Plugin
    }

    // The keys are the plugin IDs used in Device.plugins and Device.pluginsEnableStatus
    private static let pluginInfo: [NetworkPacket.`Type`: PluginInfo] = [
        .ping: PluginInfo(
            supportedPacketTypes: [.ping],
            outgoingPacketTypes: [.ping],
            create: { Ping(controlDevice: $0) }
        ),
        .share: PluginInfo(
            supportedPacketTypes: [.share, .shareRequestUpdate],
            outgoingPacketTypes: [.share, .shareRequestUpdate],
            create: { Share(controlDevice: $0) }
        ),
        .findMyPhoneRequest: PluginInfo(
            supportedPacketTypes: [.findMyPhoneRequest],
            outgoingPacketTypes: [.findMyPhoneRequest],
            create: { FindMyPhone(controlDevice: $0) }
        ),
        // The kdeconnect.battery.request packet is no longer used, but it is still the ID of this plugin
        .batteryRequest: PluginInfo(
            supportedPacketTypes: [.battery],
            outgoingPacketTypes: [.battery],
            create: { Battery(controlDevice: $0) }
        ),
        .clipboard: PluginInfo(
            supportedPacketTypes: [.clipboard, .clipboardConnect],
            outgoingPacketTypes: [.clipboard, .clipboardConnect],
            create: { Clipboard(controlDevice: $0) }
        ),
        .mousePadRequest: PluginInfo(
            supportedPacketTypes: [],
            outgoingPacketTypes: [.mousePadRequest],
            create: { RemoteInput(controlDevice: $0) }
        ),
        .presenter: PluginInfo(
            supportedPacketTypes: [],
            outgoingPacketTypes: [.mousePadRequest, .presenter],
            create: { Presenter(controlDevice: $0) }
        ),
        .runCommand: PluginInfo(
            supportedPacketTypes: [.runCommand],
            outgoingPacketTypes: [.runCommandRequest],
            create: { RunCommand(controlDevice: $0) }
        ),
    ]

    static var incomingCapabilities: [NetworkPacket.`Type`] {
        pluginInfo.values.reduce(into: Set()) { $0.formUnion($1.supportedPacketTypes) }.sorted { $0.rawValue < $1.rawValue }
    }

    static var outgoingCapabilities: [NetworkPacket.`Type`] {
        pluginInfo.values.reduce(into: Set()) { $0.formUnion($1.outgoingPacketTypes) }.sorted { $0.rawValue < $1.rawValue }
    }

    /// The IDs of the plugins that can talk to a device with the given capabilities
    @objc static func plugins(forIncomingCapabilities incoming: [NetworkPacket.`Type`],
                              outgoingCapabilities outgoing: [NetworkPacket.`Type`]) -> [NetworkPacket.`Type`] {
        return pluginInfo.filter { _, info in
            !info.supportedPacketTypes.isDisjoint(with: outgoing) || !info.outgoingPacketTypes.isDisjoint(with: incoming)
        }.keys.sorted { $0.rawValue < $1.rawValue }
    }

    @objc static func createPlugin(_ pluginID: NetworkPacket.`Type`, controlDevice: Device) -> Plugin? {
        return pluginInfo[pluginID]?.create(controlDevice)
    }
}
