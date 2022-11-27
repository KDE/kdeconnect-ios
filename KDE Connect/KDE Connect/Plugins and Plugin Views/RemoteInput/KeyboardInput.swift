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

public class KeyboardListener: UIView, UIKeyInput {
    public var hasText: Bool { false }
    public override var canBecomeFirstResponder: Bool { true }
    public override var inputAccessoryView: UIView? {
        get {
            keyboardPanel
        }
        set(panel) {
            keyboardPanel = panel
        }
    }
    
    var onInsertText: (_ text: String, _ modifiers: [RemoteInput.KeyModifier]) -> Void = { text, modifier in }
    var onDeleteBackward: () -> Void = { }
    var onReturn: () -> Void = { }
    var keyboardPanel: UIView?
    var modifiers: [RemoteInput.KeyModifier:UIButton] = [:]
    
    @objc fileprivate func ctrlPressed(_ button: UIButton) {
        button.isSelected = !button.isSelected
        if button.isSelected {
            button.backgroundColor = UIColor.link
            modifiers[.control] = button
        } else {
            button.backgroundColor = UIColor.systemBackground
            modifiers.removeValue(forKey: .control)
        }
    }
    @objc fileprivate func shiftPressed(_ button: UIButton) {
        button.isSelected = !button.isSelected
        if button.isSelected {
            button.backgroundColor = UIColor.link
            modifiers[.shift] = button
        } else {
            button.backgroundColor = UIColor.systemBackground
            modifiers.removeValue(forKey: .shift)
        }
    }
    @objc fileprivate func altPressed(_ button: UIButton) {
        button.isSelected = !button.isSelected
        if button.isSelected {
            button.backgroundColor = UIColor.link
            modifiers[.alt] = button
        } else {
            button.backgroundColor = UIColor.systemBackground
            modifiers.removeValue(forKey: .alt)
        }
    }
    
    public func insertText(_ text: String) {
        if text == "\n" {
            onReturn()
        } else {
            onInsertText(text, modifiers.keys.map {$0})
        }
        resetModifiers()
    }
    
    public func deleteBackward() {
        onDeleteBackward()
        resetModifiers()
    }
    
    private func resetModifiers() {
        if !modifiers.isEmpty {
            for button in modifiers.values {
                button.isSelected = false
                button.backgroundColor = UIColor.systemBackground
            }
            modifiers.removeAll()
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
    typealias UIViewType = KeyboardListener
    let onInsertText: (String, [RemoteInput.KeyModifier]) -> Void
    let onDeleteBackward: () -> Void
    let onReturn: () -> Void
    
    func makeUIView(context: Context) -> KeyboardListener {
        let view = KeyboardListener()
        view.onReturn = onReturn
        view.onInsertText = onInsertText
        view.onDeleteBackward = onDeleteBackward
        
        let ctrl = UIButton()
        ctrl.setTitle("Ctrl", for: .normal)
        ctrl.setTitleColor(UIColor.link, for: .normal)
        ctrl.setTitleColor(UIColor.placeholderText, for: .highlighted)
        ctrl.setTitleColor(UIColor.systemBackground, for: .selected)
        ctrl.addTarget(view, action: #selector(KeyboardListener.ctrlPressed), for: .touchDown)
        ctrl.layer.cornerRadius = 5
        ctrl.layer.borderWidth = 1
        ctrl.layer.borderColor = UIColor.clear.cgColor

        
        let shift = UIButton()
        shift.setTitle("Shift", for: .normal)
        shift.setTitleColor(UIColor.link, for: .normal)
        shift.setTitleColor(UIColor.placeholderText, for: .highlighted)
        shift.setTitleColor(UIColor.systemBackground, for: .selected)
        shift.addTarget(view, action: #selector(KeyboardListener.shiftPressed), for: .touchDown)
        shift.layer.borderColor = UIColor.clear.cgColor
        
        let alt = UIButton()
        alt.setTitle("Alt", for: .normal)
        alt.setTitleColor(UIColor.link, for: .normal)
        alt.setTitleColor(UIColor.placeholderText, for: .highlighted)
        alt.setTitleColor(UIColor.systemBackground, for: .selected)
        alt.addTarget(view, action: #selector(KeyboardListener.altPressed), for: .touchDown)
        alt.layer.borderColor = UIColor.clear.cgColor
        
        let panel = UIStackView()
        panel.backgroundColor = UIColor.systemBackground
        panel.distribution = .fillEqually
        panel.spacing = 5
        panel.frame = CGRect(x: 0, y: 0, width: 0, height: 30)
        panel.addArrangedSubview(ctrl)
        panel.addArrangedSubview(shift)
        panel.addArrangedSubview(alt)
        view.inputAccessoryView = panel
        
        return view
    }
    
    func updateUIView(_ uiView: KeyboardListener, context: Context) {
        // do nothing
    }
}
