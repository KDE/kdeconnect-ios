/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  ConnectedDevicesViewModel.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-08-09.
//

import SwiftUI
import AVFoundation
import CryptoKit
import Combine

extension Notification.Name {
    static let didReceivePairRequestNotification = Notification.Name("didReceivePairRequestNotification")
    static let pairRequestTimedOutNotification = Notification.Name("pairRequestTimedOutNotification")
    static let pairRequestSucceedNotification = Notification.Name("pairRequestSucceedNotification")
    static let pairRequestRejectedNotification = Notification.Name("pairRequestRejectedNotification")
}

@objc class ConnectedDevicesViewModel: NSObject, ObservableObject {
    @Published
    var connectedDevices: [String: String] = [:]
    @Published
    var visibleDevices: [String: String] = [:]
    @Published
    var savedDevices: [String: String] = [:]
    private let logger = Logger()
    
    @objc func onPairRequest(_ deviceId: String!) {
        NotificationCenter.default.post(name: .didReceivePairRequestNotification, object: nil,
                                        userInfo: ["deviceID": deviceId!])
    }
    
    @objc func onPairTimeout(_ deviceId: String!) {
        NotificationCenter.default.post(name: .pairRequestTimedOutNotification, object: nil,
                                        userInfo: ["deviceID": deviceId!])
    }
    
    @objc func onPairSuccess(_ deviceId: String!) {
        guard let cert = backgroundService.devices[deviceId]?._deviceInfo.cert else {
            SystemSound.audioError.play()
            logger.fault("Pairing succeeded without certificate for remote device \(deviceId!, privacy: .private(mask: .hash))")
            return
        }
        
        let status = CertificateService.shared.saveRemoteDeviceCertToKeychain(cert: cert, deviceId: deviceId)
        logger.info("Remote certificate saved into local Keychain with status \(status)")
        
        onDevicesListUpdated()
        NotificationCenter.default.post(name: .pairRequestSucceedNotification, object: nil,
                                        userInfo: ["deviceID": deviceId!])
    }
    
    @objc func onPairRejected(_ deviceId: String!) {
        NotificationCenter.default.post(name: .pairRequestRejectedNotification, object: nil,
                                        userInfo: ["deviceID": deviceId!])
    }
    
    @objc func onDevicesListUpdated(
        devicesListsMap: [String: [String: String]] = backgroundService.getDevicesLists()
    ) {
        DispatchQueue.main.async { [weak self] in
            withAnimation {
                guard let self = self else { return }
                self.connectedDevices = devicesListsMap["connected"]!
                self.visibleDevices = devicesListsMap["visible"]!
                self.savedDevices = devicesListsMap["remembered"]!
            }
        }
    }

    @objc static func isDeviceCurrentlyPairedAndConnected(_ deviceId: String) -> Bool {
        if let device = backgroundService._devices[deviceId] {
            return device.isPaired() && device.isReachable()
        }
        return false
    }
    
    @objc static func getDirectIPList() -> [String] {
        return KdeConnectSettings.shared.directIPs
    }
}
