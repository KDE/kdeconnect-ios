/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 * SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

//
//  LocalizedStringKey+Extensions.swift
//  KDE Connect
//
//  Created by Claudio Cambra on 25/5/22.
//

import Foundation
import SwiftUI

extension LocalizedStringKey.StringInterpolation {
    mutating func appendInterpolation(percent: Int) {
        if #available(iOS 15, *) {
            appendInterpolation(Double(percent) / 100, format: .percent)
        } else {
            appendInterpolation(Double(percent) / 100 as NSNumber, formatter: NumberFormatter.percentage)
        }
    }
}

fileprivate extension NumberFormatter {
    static let percentage: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        return formatter
    }()
}
