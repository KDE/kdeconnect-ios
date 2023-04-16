/*
 * SPDX-FileCopyrightText: 2022 Apollo Zhu <public-apollonian@outlook.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

//
//  iOS14+TextFormat.swift
//  KDE Connect
//
//  Created by Apollo Zhu on 11/3/22.
//

import Foundation
import SwiftUI

@available(iOS, obsoleted: 15,
           message: "Delete this file and use Foundation.FormatStyle instead.")
// Private type that should not show up in completion
// swiftlint:disable:next type_name
protocol _FormatStyle {
    associatedtype FormatInput
    func format(_ value: FormatInput) -> String
}

extension Text {
    init<F: _FormatStyle>(
        _ input: F.FormatInput, format: F
    ) where F.FormatInput: Equatable {
        self.init(format.format(input))
    }
}

extension LocalizedStringKey.StringInterpolation {
    // The _semantics attribute enables "Use compiler to Extract Swift Strings"
    // introduced in https://developer.apple.com/videos/play/wwdc2021/10221/
    // The attribute is found by looking at SwiftUI.framework's .swiftinterface
    // located at the path provided in https://forums.swift.org/t/27528/11.
    // The Foundation equivalent for String(localized:) is
    // @_semantics("localization.interpolation.appendInterpolation_@_specifier")
    @_semantics("swiftui.localized.appendInterpolation_@_specifier")
    mutating func appendInterpolation<F: _FormatStyle>(
        _ input: F.FormatInput,
        format: F
    ) where F.FormatInput: Equatable {
        // To learn more about appendInterpolation and localization, see
        // - https://onevcat.com/2021/03/swiftui-text-1/
        // - https://onevcat.com/2021/03/swiftui-text-2/
        // However, _FormatSpecifiable is not THE WAY of declaring the specifier
        // as we observe func formatSpecifier<T>(_ type: T.Type) -> String and
        // func appendInterpolation<T>(_ value: T) where T : _FormatSpecifiable.
        appendInterpolation(format.format(input))
    }
}

// MARK: - ByteCountFormatter/ByteCountFormatStyle

extension ByteCountFormatter: _FormatStyle {
    static let defaultForFile: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()
    
    func format(_ value: Int64) -> String {
        string(fromByteCount: value)
    }
}

extension _FormatStyle where Self == ByteCountFormatter {
    static func byteCount(
        style: ByteCountFormatter.CountStyle
    ) -> Self {
        switch style {
        case .file:
            return ByteCountFormatter.defaultForFile
        default:
            fatalError("Need to backport ByteCountFormatter for style: \(style)")
        }
    }
}
