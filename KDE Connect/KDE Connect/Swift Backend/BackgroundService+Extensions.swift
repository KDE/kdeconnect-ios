/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 * SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

//
//  BackgroundService+Extensions.swift
//  KDE Connect
//
//  Created by Claudio Cambra on 25/5/22.
//

import Foundation

// MARK: - Migration

// This section contains code that keeps the project compiling, but
// TODO: needs migration

// Please always use the non-deprecated spelling if possible, and
// follow the compiler warnings when ready to migrate existing code
// after uncommenting lines containing `@available`

extension BackgroundService {
    // @available(*, deprecated, renamed: "devices")
    // swiftlint:disable:next identifier_name
    var _devices: [String: Device] {
        return devices
    }
}
