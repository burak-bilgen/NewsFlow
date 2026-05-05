import Combine
import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case light
    case dark
    case system

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        case .system:
            return "System"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
}

@MainActor
final class ThemeManager: ObservableObject {
    private let key = "app.theme.preference"

    @Published private(set) var currentTheme: AppTheme

    init() {
        let stored = UserDefaults.standard.string(forKey: key) ?? "light"
        self.currentTheme = AppTheme(rawValue: stored) ?? .system
    }

    func setTheme(_ theme: AppTheme) {
        guard currentTheme != theme else { return }
        currentTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: key)
    }
}
