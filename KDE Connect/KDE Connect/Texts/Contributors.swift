/*
 * SPDX-FileCopyrightText: 2022 Apollo Zhu <public-apollonian@outlook.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  Contributors.swift
//  KDE Connect
//
//  Created by Apollo Zhu on 5/13/22.
//

import Foundation
import struct SwiftUI.Text

enum Contributors {
    case maintainers
    case authors
    
    /// sorted by KDE Identity Username, since name could be localized
    var identities: [Contributor] {
        switch self {
        case .maintainers:
            return [
                Contributor(name: "Lucas Wang", kde: "lucaswzx"),
            ]
        case .authors:
            return [
                Contributor(name: NSLocalizedString("Apollo Zhu",
                                                    comment: "Please use 朱智语 in languages with these characters."),
                            kde: "apollozhu"),
                Contributor(name: "Dan Stoian", kde: "danthedante"),
                Contributor(name: "Han Young", kde: "hanyoung"),
                Contributor(name: "James Rosson", kde: "jrosson"),
                Contributor(name: "Nicolás Alvarez", kde: "nalvarez"),
                Contributor(name: "Ruixuan Tu", kde: "ruixuantu"),
                Contributor(name: "Weixuan Xiao", kde: "wxiao"),
                Contributor(name: "Qiao YANG", kde: "yangqiao"),
                Contributor(name: "Albert Vaca Cintora", kde: "albertvaka"),
            ]
        }
    }
}

struct Contributor {
    let name: String
    let kde: String
}
