/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 * SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

//
//  KeyEvent.swift
//  KDE Connect
//
//  Created by Claudio Cambra on 25/5/22.
//

import Foundation

// Uniform Key inputs
// swiftlint:disable identifier_name

// KeyEvent is NOT a part of any iOS API, it's a custom enum
// KeyEvent is indeed part of AppKit for macOS (but not any other OS), and SwiftUI for iOS does have
// limited support, but at this time ONLY for external keyboards.
// All of these matches the Android SpecialKeysMap as defined in KeyListenerView.java
// Even if a lot of them are not used in iOS
enum KeyEvent: Int {
    case KEYCODE_DEL            = 1
    case KEYCODE_TAB            = 2
    // 3 is not used, ENTER share the same value as NUMPAD_ENTER, 12
    case KEYCODE_DPAD_LEFT      = 4
    case KEYCODE_DPAD_UP        = 5
    case KEYCODE_DPAD_RIGHT     = 6
    case KEYCODE_DPAD_DOWN      = 7
    case KEYCODE_PAGE_UP        = 8
    case KEYCODE_PAGE_DOWN      = 9
    case KEYCODE_MOVE_HOME      = 10
    case KEYCODE_MOVE_END       = 11
    //case KEYCODE_NUMPAD_ENTER   = 12
    case KEYCODE_ENTER          = 12
    case KEYCODE_FORWARD_DEL    = 13
    case KEYCODE_ESCAPE         = 14
    case KEYCODE_SYSRQ          = 15
    case KEYCODE_SCROLL_LOCK    = 16
    // 17 is not used
    // 18 is not used
    // 19 is not used
    // 20 is not used
    case KEYCODE_F1             = 21
    case KEYCODE_F2             = 22
    case KEYCODE_F3             = 23
    case KEYCODE_F4             = 24
    case KEYCODE_F5             = 25
    case KEYCODE_F6             = 26
    case KEYCODE_F7             = 27
    case KEYCODE_F8             = 28
    case KEYCODE_F9             = 29
    case KEYCODE_F10            = 30
    case KEYCODE_F11            = 31
    case KEYCODE_F12            = 32
}
// swiftlint:enable identifier_name
