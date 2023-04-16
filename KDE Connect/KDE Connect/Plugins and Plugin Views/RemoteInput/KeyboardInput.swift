/*
 * SPDX-FileCopyrightText: 2022 Han Young <hanyoung@protonmail.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import UIKit
import SwiftUI
import Introspect

extension View {
    public func introspectKeyboardListener(customize: @escaping (KeyboardListener) -> Void) -> some View {
        introspect(selector: TargetViewSelector.siblingContainingOrAncestorOrAncestorChild, customize: customize)
    }
}

public class KeyboardListener: UIView, UIKeyInput {
    public var hasText: Bool { false }
    public override var canBecomeFirstResponder: Bool { true }
    
    var onInsertText: (_ text: String) -> Void = { text in }
    var onDeleteBackward: () -> Void = { }
    var onReturn: () -> Void = { }
    
    public func insertText(_ text: String) {
        if text == "\n" {
            onReturn()
        } else {
            onInsertText(text)
        }
    }
    
    public func deleteBackward() {
        onDeleteBackward()
    }
}

// This naming is intentional to mimic a SwiftUI View
// swiftlint:disable:next identifier_name
func KeyboardListenerPlaceholderView(onInsertText: @escaping (String) -> Void = {_ in },
                                     onDeleteBackward: @escaping () -> Void = {},
                                     onReturn: @escaping () -> Void = {}) -> some View {
    
    return _KeyboardListenerPlaceholderView(onInsertText: onInsertText,
                                            onDeleteBackward: onDeleteBackward,
                                            onReturn: onReturn)
    .frame(width: 0, height: 0)
}

fileprivate struct _KeyboardListenerPlaceholderView: UIViewRepresentable {
    typealias UIViewType = KeyboardListener
    let onInsertText: (String) -> Void
    let onDeleteBackward: () -> Void
    let onReturn: () -> Void
    
    func makeUIView(context: Context) -> KeyboardListener {
        let view = KeyboardListener()
        view.onReturn = onReturn
        view.onInsertText = onInsertText
        view.onDeleteBackward = onDeleteBackward
        return view
    }
    
    func updateUIView(_ uiView: KeyboardListener, context: Context) {
        // do nothing
    }
}
