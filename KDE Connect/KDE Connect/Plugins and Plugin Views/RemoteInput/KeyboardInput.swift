/* 
 * SPDX-FileCopyrightText: 2022 Han Young <hanyoung@protonmail.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import UIKit
import SwiftUI
import Introspect

extension View {
    public func introspectKeyboardListener(customize: @escaping (KeyboardListener) -> ()) -> some View {
        introspect(selector: TargetViewSelector.siblingContainingOrAncestorOrAncestorChild, customize: customize)
    }
}

public protocol KeyboardListenerDelegate {
    func onInsertText(_ text: String) -> Void
    func onDeleteBackward() -> Void
    func onReturn() -> Void
}

public class KeyboardListener: UIView, UIKeyInput {
    public var hasText: Bool { false }
    public override var canBecomeFirstResponder: Bool { true }
    public var delegate: KeyboardListenerDelegate?
    
    private var _keyboardPanel: UIView?
    public override var inputAccessoryView: UIView? {
        get {
            _keyboardPanel
        }
        set {
            _keyboardPanel = newValue
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
        if let delegate = delegate {
            delegate.onDeleteBackward()
        }
    }
}

func KeyboardListenerPlaceholderView(onInsertText: @escaping (String, [RemoteInput.KeyModifier]) -> Void = {_, _ in },
                                     onDeleteBackward: @escaping () -> Void = {},
                                     onReturn: @escaping () -> Void = {}) -> some View {
    
    return _KeyboardListenerPlaceholderView(onInsertText: onInsertText,
                                            onDeleteBackward: onDeleteBackward,
                                            onReturn: onReturn)
    .frame(width: 0, height: 0)
}

fileprivate struct _KeyboardListenerPlaceholderView: UIViewRepresentable {
    class Coordinator: NSObject, KeyboardListenerDelegate {
        private var parent: _KeyboardListenerPlaceholderView
        private var currentModifiers: [RemoteInput.KeyModifier:UIButton] = [:]
        
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
    }
    
    typealias UIViewType = KeyboardListener
    let onInsertText: (String, [RemoteInput.KeyModifier]) -> Void
    let onDeleteBackward: () -> Void
    let onReturn: () -> Void
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func makeUIView(context: Context) -> KeyboardListener {
        let view = KeyboardListener()
        
        let createButton: (String, Selector) -> UIButton = { name, selector in
            let btn = UIButton()
            btn.setTitle(name, for: .normal)
            btn.setTitleColor(UIColor.link, for: .normal)
            btn.setTitleColor(UIColor.placeholderText, for: .highlighted)
            btn.setTitleColor(UIColor.systemBackground, for: .selected)
            btn.addTarget(context.coordinator, action: selector, for: .touchDown)
            btn.layer.cornerRadius = 8
            btn.layer.cornerCurve = .continuous
            btn.layer.borderWidth = 1
            btn.layer.borderColor = UIColor.clear.cgColor
            return btn
        }
        
        let ctrl = createButton("Ctrl", #selector(Coordinator.ctrlPressed))
        let shift = createButton("Shift", #selector(Coordinator.shiftPressed))
        let alt = createButton("Alt", #selector(Coordinator.altPressed))
        
        let panel = UIStackView()
        panel.backgroundColor = UIColor.systemBackground
        panel.distribution = .fillEqually
        panel.spacing = 5
        panel.frame = CGRect(x: 0, y: 0, width: 0, height: 30)
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
