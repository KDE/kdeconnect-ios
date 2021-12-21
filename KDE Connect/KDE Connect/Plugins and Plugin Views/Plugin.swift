/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
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
}

typealias ObservablePlugin = Plugin & ObservableObject
