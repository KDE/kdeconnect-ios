/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  TapRecognizerViewModifier.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-09-06.
//

import SwiftUI

struct TapRecognizerViewModifier: ViewModifier {
    
    @State private var singleTapIsTaped: Bool = Bool()
    
    var tapSensitivity: Double
    var singleTapAction: () -> Void
    var doubleTapAction: () -> Void
    
    init(tapSensitivity: Double, singleTapAction: @escaping () -> Void, doubleTapAction: @escaping () -> Void) {
        self.tapSensitivity = tapSensitivity
        self.singleTapAction = singleTapAction
        self.doubleTapAction = doubleTapAction
    }
    
    func body(content: Content) -> some View {
        
        return content
            .gesture(simultaneouslyGesture)
        
    }
    
    private var singleTapGesture: some Gesture { TapGesture(count: 1).onEnded{
        
        singleTapIsTaped = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + tapSensitivity) { if singleTapIsTaped { singleTapAction() } }
        
    } }
    
    private var doubleTapGesture: some Gesture { TapGesture(count: 2).onEnded{ singleTapIsTaped = false; doubleTapAction() } }
    
    private var simultaneouslyGesture: some Gesture { singleTapGesture.simultaneously(with: doubleTapGesture) }
    
}


extension View {
    
    func tapRecognizer(tapSensitivity: Double, singleTapAction: @escaping () -> Void, doubleTapAction: @escaping () -> Void) -> some View {
        
        return self.modifier(TapRecognizerViewModifier(tapSensitivity: tapSensitivity, singleTapAction: singleTapAction, doubleTapAction: doubleTapAction))
        
    }
    
}
