import SwiftUI
import UIKit

enum Theme {
    static let cardRadius: CGFloat = 12
    static let badgeRadius: CGFloat = 6
    static let bubbleRadius: CGFloat = 16

    static let cardFillOpacity: Double = 0.06
    static let cardBorderOpacity: Double = 0.3
    static let cardBorderWidth: CGFloat = 1

    static let springAnimation = Animation.spring(duration: 0.3, bounce: 0.12)
    static let springTransition = AnyTransition.opacity.combined(with: .scale(scale: 0.97, anchor: .top))
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
