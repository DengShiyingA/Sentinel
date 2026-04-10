import SwiftUI
import UIKit

enum Theme {
    // MARK: - Layout
    static let cardRadius: CGFloat = 12
    static let badgeRadius: CGFloat = 6
    static let bubbleRadius: CGFloat = 16

    static let cardFillOpacity: Double = 0.06
    static let cardBorderOpacity: Double = 0.3
    static let cardBorderWidth: CGFloat = 1

    // MARK: - Animation
    static let springAnimation = Animation.spring(duration: 0.3, bounce: 0.12)
    static let springTransition = AnyTransition.opacity.combined(with: .scale(scale: 0.97, anchor: .top))

    // MARK: - Claude Color Palette
    /// Claude's primary brand coral/terracotta
    static let claude = Color(red: 0.855, green: 0.467, blue: 0.337)        // #DA7756
    static let claudeDark = Color(red: 0.788, green: 0.416, blue: 0.282)    // #C96A48
    static let claudeLight = Color(red: 0.855, green: 0.467, blue: 0.337).opacity(0.15)

    /// Use these instead of raw .teal / .blue for branded elements
    static let accent: Color = claude
    static let accentDark: Color = claudeDark
    static let accentLight: Color = claudeLight
}

enum Haptic {
    static func allow() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func block() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    static func warning() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
