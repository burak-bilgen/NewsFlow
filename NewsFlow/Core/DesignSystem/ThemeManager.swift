import SwiftUI
import Combine

enum AppTheme: String, CaseIterable, Identifiable {
    case light
    case dark
    case system

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    private let key = "app.theme.preference"

    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: key)
        }
    }

    init() {
        let stored = UserDefaults.standard.string(forKey: key) ?? "system"
        self.currentTheme = AppTheme(rawValue: stored) ?? .system
    }

    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
    }
}
