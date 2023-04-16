/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 * SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

//
//  Device+Extensions.swift
//  KDE Connect
//
//  Created by Claudio Cambra on 25/5/22.
//

import Foundation

extension Device {
    @objc
    @available(swift, obsoleted: 1.0, message: "Use 'DeviceType.current' instead")
    static var currentDeviceType: DeviceType {
        return DeviceType.current
    }
    
    // MARK: - Migration
    
    // This section contains code that keeps the project compiling, but
    // TODO: needs migration
    // swiftlint:disable identifier_name

    // Please always use the non-deprecated spelling if possible, and
    // follow the compiler warnings when ready to migrate existing code
    // after uncommenting lines containing `@available`
    
    // @available(*, deprecated, renamed: "plugins")
    var _plugins: [NetworkPackage.`Type`: Plugin] {
        plugins
    }

    // @available(*, deprecated, renamed: "pluginsEnableStatus")
    var _pluginsEnableStatus: [NetworkPackage.`Type`: NSNumber] {
        get {
            pluginsEnableStatus
        }
        set {
            pluginsEnableStatus = newValue
        }
    }
}
// swiftlint:enable identifier_name
