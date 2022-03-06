/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  TwoFingerTapView.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-09-06.
//

import UIKit
import SwiftUI

struct TwoFingerTapView: UIViewRepresentable
{
    var tapCallback: (UITapGestureRecognizer) -> Void
    
    typealias UIViewType = UIView
    
    func makeCoordinator() -> TwoFingerTapView.Coordinator
    {
        Coordinator(tapCallback: self.tapCallback)
    }
    
    func makeUIView(context: UIViewRepresentableContext<TwoFingerTapView>) -> UIView
    {
        let view = UIView()
        view.backgroundColor = .systemBackground
        let twoFingerTapGestureRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(sender:)))
        
        // Set number of touches.
        twoFingerTapGestureRecognizer.numberOfTouchesRequired = 2
        
        view.addGestureRecognizer(twoFingerTapGestureRecognizer)
        
        let instructionLabel: UILabel = UILabel()
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel.textAlignment = .right
        instructionLabel.text = "Move a finger on the screen to move the mouse cursor. Tap with one finger for left click. Tap with two fingers for right click. Use a long press to activate drag'n drop. Or use the menu on the top right to directly send clicks.\n\nDrag with one finger from the \"Scroll Wheel\" above to scroll both vertically and horizontally. Tap on the \"Scroll Wheel\" for middle click."
        instructionLabel.numberOfLines = 12
        instructionLabel.textAlignment = .center
        view.addSubview(instructionLabel)
        
        NSLayoutConstraint.activate([
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            instructionLabel.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: UIScreen.main.bounds.height / 4),
        ])
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<TwoFingerTapView>)
    {
    }
    
    class Coordinator
    {
        var tapCallback: (UITapGestureRecognizer) -> Void
        
        init(tapCallback: @escaping (UITapGestureRecognizer) -> Void)
        {
            self.tapCallback = tapCallback
        }
        
        @objc func handleTap(sender: UITapGestureRecognizer)
        {
            self.tapCallback(sender)
        }
    }
}
