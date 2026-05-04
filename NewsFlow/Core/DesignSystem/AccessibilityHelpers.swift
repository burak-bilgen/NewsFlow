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
    func accessibleAnimation(_ animation: Animation?) -> some View {
        if Accessibility.isReduceMotionEnabled {
            return self.animation(nil)
        } else {
            return self.animation(animation)
        }
    }
}
