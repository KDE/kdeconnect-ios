/*
 * SPDX-FileCopyrightText: 2022 Apollo Zhu <public-apollonian@outlook.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  iOS14+FocusState.swift
//  KDE Connect
//
//  Created by Apollo Zhu on 4/24/22.
//

import SwiftUI
import Introspect

@available(iOS, obsoleted: 15, message: "Delete this file and use SwiftUI.FocusState instead.")
typealias FocusState = State

extension View {
    /// See ``ConfigureDeviceByIPView`` for example.
    ///
    /// - Warning: Update `binding` inside `withAnimation` has no effect.
    @ViewBuilder
    func focused<T: Hashable>(_ binding: Binding<T?>, equals value: T?) -> some View {
        modifier(Focuser(binding, equals: value))
    }
    
    @ViewBuilder
    func focused(_ binding: Binding<Bool>) -> some View {
        modifier(Focuser(binding.asOptional, equals: true))
    }
}

fileprivate extension Bool {
    var asOptional: Bool? {
        get { self }
        set { self = newValue == true }
    }
}

/// Intercepts all UITextFieldDelegate methods and forwarding them to original,
/// but additionally calling ``didBeginEditing`` and ``didEndEditing``.
fileprivate class UITextFieldDelegateFocusProxy: NSObject, UITextFieldDelegate {
    weak var forwardingDelegate: UITextFieldDelegate?
    var didBeginEditing: () -> Void = { }
    var didEndEditing: () -> Void = { }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        forwardingDelegate?.textFieldDidBeginEditing?(textField)
        didBeginEditing()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        forwardingDelegate?.textFieldDidEndEditing?(textField)
        didEndEditing()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        forwardingDelegate?.textFieldDidEndEditing?(textField, reason: reason)
        didEndEditing()
    }
    
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return forwardingDelegate
    }
    
    override func responds(to aSelector: Selector!) -> Bool {
        return super.responds(to: aSelector)
            || (forwardingDelegate?.responds(to: aSelector) ?? false)
    }
}

fileprivate struct Focuser<Value: Hashable>: ViewModifier {
    @Binding private var binding: Value?
    private let value: Value?
    private let proxy = UITextFieldDelegateFocusProxy()
    
    init(_ binding: Binding<Value?>, equals value: Value?) {
        self._binding = binding
        self.value = value
    }
    
    func body(content: Content) -> some View {
        content
            .introspectTextField { textField in
                if !(textField.delegate is UITextFieldDelegateFocusProxy) {
                    proxy.forwardingDelegate = textField.delegate
                    proxy.didBeginEditing = { binding = value }
                    proxy.didEndEditing = { binding = nil }
                    textField.delegate = proxy
                }
                if binding == value {
                    textField.becomeFirstResponder()
                } else if textField.isFirstResponder {
                    textField.resignFirstResponder()
                }
            }
            .onChange(of: binding) { _ in
                // trigger view update
            }
            .introspectKeyboardListener { listener in
                if binding == value {
                    listener.becomeFirstResponder()
                } else if listener.isFirstResponder {
                    listener.resignFirstResponder()
                }
            }
    }
}
