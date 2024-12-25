//
//  Haptics.swift
//  KDE Connect
//
//  Created by Claudio Cambra on 25/5/22.
//

#if !os(macOS)

import Foundation
import SwiftUI

// Haptics provider, for a list of the enum values see
// https://developer.apple.com/documentation/uikit/uiimpactfeedbackgenerator/feedbackstyle
extension UIImpactFeedbackGenerator.FeedbackStyle: CaseIterable {
    public var text: Text {
        switch self {
        case .light: return Text("Light", comment: "Light haptic feedback level")
        case .medium: return Text("Medium", comment: "Medium haptic feedback level")
        case .heavy: return Text("Heavy", comment: "Hard haptic feedback level")
        case .soft: return Text("Soft", comment: "Soft haptic feedback level")
        case .rigid: return Text("Rigid", comment: "Rigid haptic feedback level")
        @unknown default: return Text("Other", comment: "Unknown haptic feedback level")
        }
    }
    
    public static var allCases: [UIImpactFeedbackGenerator.FeedbackStyle] {
        return [.light, .medium, .heavy, .soft, .rigid]
    }
}

// UIImpactFeedbackGenerator.FeedbackStyle.init(rawValue: Int)

let notificationHapticsGenerator: UINotificationFeedbackGenerator = UINotificationFeedbackGenerator()

#endif
