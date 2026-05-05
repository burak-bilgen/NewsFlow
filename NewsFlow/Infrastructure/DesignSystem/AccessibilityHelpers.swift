import SwiftUI

enum Accessibility {
    static var isReduceMotionEnabled: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    static var isVoiceOverRunning: Bool {
        UIAccessibility.isVoiceOverRunning
    }

    static var isBoldTextEnabled: Bool {
        UIAccessibility.isBoldTextEnabled
    }
}

extension View {
    func accessibleAnimation<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        if Accessibility.isReduceMotionEnabled {
            return self.animation(nil, value: value)
        } else {
            return self.animation(animation, value: value)
        }
    }
}
