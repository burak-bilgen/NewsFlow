import Combine
import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case light
    case dark
    case system

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: return L10n.text("theme.light")
        case .dark: return L10n.text("theme.dark")
        case .system: return L10n.text("theme.system")
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
        let stored = UserDefaults.standard.string(forKey: key)
        self.currentTheme = AppTheme(rawValue: stored ?? "") ?? .light
    }

    func setTheme(_ theme: AppTheme) {
        guard currentTheme != theme else { return }
        currentTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: key)
    }
}
