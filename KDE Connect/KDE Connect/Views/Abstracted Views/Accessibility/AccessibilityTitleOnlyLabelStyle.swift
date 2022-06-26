/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  AccessibilityTitleOnlyLabelStyle.swift
//  KDE Connect
//
//  Created by Apollo Zhu on 2/24/22.
//

import SwiftUI

struct AccessibilityTitleOnlyLabelStyle: LabelStyle {
    @Environment(\.sizeCategory) var dynamicTypeSize
    
    func makeBody(configuration: Configuration) -> some View {
        if dynamicTypeSize.isAccessibilityCategory {
            TitleOnlyLabelStyle().makeBody(configuration: configuration)
        } else {
            DefaultLabelStyle().makeBody(configuration: configuration)
        }
    }
}

extension LabelStyle where Self == AccessibilityTitleOnlyLabelStyle {
    static var accessibilityTitleOnly: Self { Self() }
}
