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
                Contributor(name: NSLocalizedString("Apollo Zhu",
                                                    comment: "Please use 朱智语 in languages with these characters."),
                            kde: "apollozhu"),
                Contributor(name: NSLocalizedString("Lucas Wang", comment: ""), kde: "lucaswzx"),
            ]
        case .authors:
            return [
                Contributor(name: NSLocalizedString("Dan Stoian", comment: ""), kde: "danthedante"),
                Contributor(name: NSLocalizedString("Han Young", comment: ""), kde: "hanyoung"),
                Contributor(name: NSLocalizedString("Nicolás Alvarez", comment: ""), kde: "nalvarez"),
                Contributor(name: NSLocalizedString("Ruixuan Tu", comment: ""), kde: "ruixuantu"),
                Contributor(name: NSLocalizedString("Wenxuan Xiao", comment: ""), kde: "wxiao"),
                Contributor(name: NSLocalizedString("Qiao YANG", comment: ""), kde: "yangqiao"),
            ]
        }
    }
}

struct Contributor {
    let name: String
    let kde: String
}
