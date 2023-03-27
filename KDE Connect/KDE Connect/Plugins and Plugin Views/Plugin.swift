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
    @objc func onDevicePackageReceived(np: NetworkPackage) -> Bool
    @objc optional func onPackage(_ np: NetworkPackage,
                                  sentWithPackageTag packageTag: Int)
    @objc optional func onPackage(_ np: NetworkPackage,
                                  sendWithPackageTag packageTag: Int,
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
