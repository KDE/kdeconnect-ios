/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import SwiftUI

@available(iOS, obsoleted: 15, message: "Delete iOS 14 compatibility and rebuild")
extension View {
    @ViewBuilder
    func alert(
        _ titleKey: LocalizedStringKey,
        isPresented: Binding<Bool>,
        @AlertActionBuilder actions: () -> AlertActionBuilder.Buttons?,
        @ViewBuilder message: () -> Text?
    ) -> some View {
        if #available(iOS 15, *) {
            self.alert(
                titleKey,
                isPresented: isPresented,
                actions: {
                    switch actions() {
                    case nil:
                        EmptyView()
                    case .dismiss(let button):
                        button.button
                    case .primary(let primary, secondary: let secondary):
                        primary.button
                        secondary.button
                    }
                },
                message: message
            )
        } else {
            self
                .alert(isPresented: isPresented) {
                    switch actions() {
                    case nil:
                        return Alert(
                            title: Text(titleKey),
                            message: message()
                        )
                    case .dismiss(let button):
                        return Alert(
                            title: Text(titleKey),
                            message: message(),
                            dismissButton: button.alertButton
                        )
                    case .primary(let primary, secondary: let secondary):
                        return Alert(
                            title: Text(titleKey),
                            message: message(),
                            primaryButton: primary.alertButton,
                            secondaryButton: secondary.alertButton
                        )
                    }
                }
        }
    }
}

@available(iOS, deprecated: 15)
// This naming is intentional in tricking the compiler
// swiftlint:disable:next identifier_name
func Button(
    _ titleKey: LocalizedStringKey,
    role: _Button.Role? = nil,
    action: @escaping () -> Void
) -> _Button {
    _Button(titleKey, role: role, action: action)
}

@available(iOS, deprecated: 15)
// Private type that should not show up in completion
// swiftlint:disable:next type_name
struct _Button {
    @available(iOS, deprecated: 15)
    enum Role {
        case cancel
        case destructive
        
        @available(iOS, introduced: 15)
        fileprivate var buttonRole: ButtonRole {
            switch self {
            case .cancel: return .cancel
            case .destructive: return .destructive
            }
        }
    }
    
    private let titleKey: LocalizedStringKey
    fileprivate let role: Role?
    private let action: () -> Void
    
    fileprivate init(_ titleKey: LocalizedStringKey, role: Role? = nil, action: @escaping () -> Void) {
        self.titleKey = titleKey
        self.role = role
        self.action = action
    }
    
    @available(iOS, introduced: 15)
    fileprivate var button: some View {
        Button(titleKey, role: role?.buttonRole, action: action)
    }
    
    @available(iOS, deprecated: 15)
    fileprivate var alertButton: Alert.Button {
        switch role {
        case .destructive:
            return .destructive(Text(titleKey), action: action)
        case .cancel:
            return .cancel(Text(titleKey), action: action)
        case nil:
            return .default(Text(titleKey), action: action)
        }
    }
}

@available(iOS, deprecated: 15)
@resultBuilder
enum AlertActionBuilder {
    enum Buttons {
        case dismiss(_Button)
        case primary(_Button, secondary: _Button)
    }
    
    static func buildBlock() -> Buttons? {
        return nil
    }
    
    static func buildBlock(_ button: _Button) -> Buttons? {
        return .dismiss(button)
    }
    
    static func buildBlock(_ button1: _Button, _ button2: _Button) -> Buttons? {
        switch (button1.role, button2.role) {
        case (.cancel, .cancel):
            break
        case (.cancel, _):
            return .primary(button2, secondary: button1)
        case (_, .cancel):
            return .primary(button1, secondary: button2)
        default:
            break
        }
        fatalError("Can't decide which one is primary")
    }
}

@available(iOS, introduced: 14, obsoleted: 15, message: "Delete this extension")
extension View {
    /// TODO: implement refreshable for iOS 14?
    @ViewBuilder
    func refreshable(_ action: @escaping @Sendable () async -> Void) -> some View {
        if #available(iOS 15, *) {
            self.refreshable(action: action)
        } else {
            self
        }
    }
}

@available(iOS, introduced: 14, obsoleted: 15, message: "Delete this extension")
extension View {
    @ViewBuilder
    func onSubmit(action: @escaping (() -> Void)) -> some View {
        if #available(iOS 15, *) {
            self.onSubmit(action)
        } else {
            // ConfigureDeviceByIPView requires onSubmit to be no-op on iOS 14
            self
        }
    }
}

@available(iOS, introduced: 14, obsoleted: 15)
struct MonospacedDigits: ViewModifier {
    @Environment(\.font) var font

    func body(content: Content) -> some View {
        if #available(iOS 15, *) {
            content
                .monospacedDigit()
        } else if let font = font {
            content
                .font(font.monospacedDigit())
        } else {
            content
        }
    }
}

@available(iOS, introduced: 14, obsoleted: 15)
extension Text {
    func monospacedDigit() -> some View {
        modifier(MonospacedDigits())
    }
}

@available(iOS, introduced: 14, obsoleted: 15, message: "Delete this extension")
extension View {
    @ViewBuilder
    func bottomOverlay<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        if #available(iOS 15, *) {
            self.overlay(alignment: .bottom, content: content)
        } else {
            VStack {
                Spacer()
                content()
            }
        }
    }
}
