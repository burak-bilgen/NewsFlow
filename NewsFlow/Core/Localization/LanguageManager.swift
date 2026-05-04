import Combine
import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case turkish = "tr"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .turkish:
            return "Türkçe"
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
        self.currentLanguage = AppLanguage(rawValue: stored) ?? .turkish
    }

    func setLanguage(_ language: AppLanguage) {
        guard currentLanguage != language else { return }
        currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: key)
        UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
    }
}
