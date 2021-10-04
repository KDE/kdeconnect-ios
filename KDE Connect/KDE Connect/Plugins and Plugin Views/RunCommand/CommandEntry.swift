/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  CommandEntry.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-09-16.
//

import Foundation

class CommandEntry: Decodable {
    final var name: String
    final var command: String
    final var key: String?
    
//    init(name: String, cmd: String, key: String) {
//        self.name = name
//        self.cmd = cmd
//        self.key = key
//    }
}
