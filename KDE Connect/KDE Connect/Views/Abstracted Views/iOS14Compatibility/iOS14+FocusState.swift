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
        modifier(iOS14Focus(binding, equals: value))
    }
}

/// Intercepts all UITextFieldDelegate methods and forwarding them to original,
/// but additionally calling ``didBeginEditing`` and ``didEndEditing``.
fileprivate class UITextFieldDelegateiOS14FocusProxy: NSObject, UITextFieldDelegate {
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

fileprivate struct iOS14Focus<Value: Hashable>: ViewModifier {
    @Binding private var binding: Value?
    private let value: Value?
    private let textFieldDelegate = UITextFieldDelegateiOS14FocusProxy()
    
    init(_ binding: Binding<Value?>, equals value: Value?){
        self._binding = binding
        self.value = value
    }
    
    func body(content: Content) -> some View {
        content
            .introspectTextField { textField in
                if !(textField.delegate is UITextFieldDelegateiOS14FocusProxy) {
                    textFieldDelegate.forwardingDelegate = textField.delegate
                    textFieldDelegate.didBeginEditing = { binding = value }
                    textFieldDelegate.didEndEditing = { binding = nil }
                    textField.delegate = textFieldDelegate
                }
                if binding == value {
                    textField.becomeFirstResponder()
                }
            }
            .onChange(of: binding) { _ in
                // trigger view update
            }
    }
}
