import Combine
import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case turkish = "tr"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return L10n.text("language.english")
        case .turkish: return L10n.text("language.turkish")
        }
    }

    var localeIdentifier: String {
        rawValue
    }
}

@MainActor
final class LanguageManager: ObservableObject {
    private let key = "app.language.preference"

    @Published private(set) var currentLanguage: AppLanguage

    init() {
        let stored = UserDefaults.standard.string(forKey: key) ?? ""
        self.currentLanguage = AppLanguage(rawValue: stored) ?? .english
    }

    func setLanguage(_ language: AppLanguage) {
        guard currentLanguage != language else { return }
        currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: key)
        UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
        L10n.invalidateCache()
    }
}
