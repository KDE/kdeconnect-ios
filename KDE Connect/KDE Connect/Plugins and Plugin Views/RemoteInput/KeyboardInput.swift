/*
 * SPDX-FileCopyrightText: 2022 Han Young <hanyoung@protonmail.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#if !os(macOS)

import UIKit
import SwiftUI
import Introspect

extension View {
    public func introspectKeyboardListener(customize: @escaping (KeyboardListener) -> Void) -> some View {
        introspect(selector: TargetViewSelector.siblingContainingOrAncestorOrAncestorChild, customize: customize)
    }
}

public protocol KeyboardListenerDelegate: AnyObject {
    func onInsertText(_ text: String)
    func onDeleteBackward()
    func onReturn()
}

public class KeyboardListener: UIView, UIKeyInput {
    public var hasText: Bool { false }
    public override var canBecomeFirstResponder: Bool { true }
    public weak var delegate: KeyboardListenerDelegate?
    
    private var _inputAccessoryView: UIView?
    public override var inputAccessoryView: UIView? {
        get {
            _inputAccessoryView
        }
        set {
            _inputAccessoryView = newValue
        }
    }
    
    public func insertText(_ text: String) {
        if let delegate = delegate {
            if text == "\n" {
                delegate.onReturn()
            } else {
                delegate.onInsertText(text)
            }
        }
    }
    
    public func deleteBackward() {
        delegate?.onDeleteBackward()
    }
}

// This naming is intentional to mimic a SwiftUI View
// swiftlint:disable:next identifier_name
func KeyboardListenerPlaceholderView(
    onInsertText: @escaping (String, [RemoteInput.KeyModifier]) -> Void = { _, _ in },
    onDeleteBackward: @escaping () -> Void = {},
    onReturn: @escaping () -> Void = {},
    onTab: @escaping () -> Void = {}
) -> some View {
    return _KeyboardListenerPlaceholderView(onInsertText: onInsertText,
                                            onDeleteBackward: onDeleteBackward,
                                            onReturn: onReturn,
                                            onTab: onTab)
    .frame(width: 0, height: 0)
}

fileprivate struct _KeyboardListenerPlaceholderView: UIViewRepresentable {
    class Coordinator: NSObject, KeyboardListenerDelegate {
        private var parent: _KeyboardListenerPlaceholderView
        private var currentModifiers: [RemoteInput.KeyModifier: UIButton] = [:]
        
        init(_ parent: _KeyboardListenerPlaceholderView) {
            self.parent = parent
        }
        
        func onInsertText(_ text: String) {
            parent.onInsertText(text, Array(currentModifiers.keys))
            resetModifiers()
        }
        
        func onDeleteBackward() {
            parent.onDeleteBackward()
            resetModifiers()
        }
        
        func onReturn() {
            parent.onReturn()
            resetModifiers()
        }
        
        private func resetModifiers() {
            if !currentModifiers.isEmpty {
                for button in currentModifiers.values {
                    button.isSelected = false
                    button.backgroundColor = UIColor.systemBackground
                }
                currentModifiers.removeAll()
            }
        }
        
        private func modifierPressed(_ button: UIButton, type: RemoteInput.KeyModifier) {
            button.isSelected.toggle()
            if button.isSelected {
                button.backgroundColor = UIColor.link
                currentModifiers[type] = button
            } else {
                button.backgroundColor = UIColor.systemBackground
                currentModifiers.removeValue(forKey: type)
            }
        }
        @objc func ctrlPressed(_ button: UIButton) {
            modifierPressed(button, type: .control)
        }
        @objc func shiftPressed(_ button: UIButton) {
            modifierPressed(button, type: .shift)
        }
        @objc func altPressed(_ button: UIButton) {
            modifierPressed(button, type: .alt)
        }
        @objc func tabPressed(_ button: UIButton) {
            parent.onTab()
        }
    }
    
    typealias UIViewType = KeyboardListener
    let onInsertText: (String, [RemoteInput.KeyModifier]) -> Void
    let onDeleteBackward: () -> Void
    let onReturn: () -> Void
    let onTab: () -> Void
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func makeUIView(context: Context) -> KeyboardListener {
        let view = KeyboardListener()
        
        let createButton: (String, @escaping (UIButton) -> Void) -> UIButton = { name, actionHandler in
            let button = UIButton()
            button.setTitle(name, for: .normal)
            button.setTitleColor(UIColor.link, for: .normal)
            button.setTitleColor(UIColor.placeholderText, for: .highlighted)
            button.setTitleColor(UIColor.systemBackground, for: .selected)
            button.backgroundColor = UIColor.systemBackground
            button.layer.cornerRadius = 8
            button.layer.cornerCurve = .continuous
            button.layer.borderWidth = 0
            
            let action = UIAction { _ in
                actionHandler(button)
            }
            button.addAction(action, for: .touchUpInside)
            return button
        }
        
        let tab = createButton("Tab") { sender in
            context.coordinator.tabPressed(sender)
        }
        let ctrl = createButton("Ctrl") { sender in
            context.coordinator.ctrlPressed(sender)
        }
        let shift = createButton("Shift") { sender in
            context.coordinator.shiftPressed(sender)
        }
        let alt = createButton("Alt") { sender in
            context.coordinator.altPressed(sender)
        }
        
        let panel = UIStackView()
        panel.backgroundColor = UIColor.systemBackground
        panel.distribution = .fillEqually
        panel.spacing = 8
        panel.frame = CGRect(x: 0, y: 0, width: 0, height: 30)
        panel.addArrangedSubview(tab)
        panel.addArrangedSubview(ctrl)
        panel.addArrangedSubview(shift)
        panel.addArrangedSubview(alt)
        
        view.inputAccessoryView = panel
        view.delegate = context.coordinator
        
        return view
    }
    
    func updateUIView(_ uiView: KeyboardListener, context: Context) {
        // do nothing
    }
}

#endif
