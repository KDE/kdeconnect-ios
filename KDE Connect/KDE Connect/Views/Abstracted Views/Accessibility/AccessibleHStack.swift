/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  AccessibleHStack.swift
//  KDE Connect
//
//  Created by Apollo Zhu on 2/24/22.
//

import SwiftUI

struct AccessibleHStack<Content: View>: View {
    @Environment(\.sizeCategory) var dynamicTypeSize
    
    let alignment: VerticalAlignment
    let spacing: CGFloat?
    let content: () -> Content
    
    init(alignment: VerticalAlignment = .center,
         spacing: CGFloat? = nil,
         @ViewBuilder content: @escaping () -> Content) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        if dynamicTypeSize.isAccessibilityCategory {
            VStack(alignment: .leading) {
                content()
            }
        } else {
            HStack(alignment: alignment, spacing: spacing, content: content)
        }
    }
}

struct AccessibleHStack_Previews: PreviewProvider {
    static var previews: some View {
        AccessibleHStack {
            Text("A")
            Text("B")
        }
    }
}
