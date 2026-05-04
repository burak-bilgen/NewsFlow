import Foundation

enum L10n {
    private static var cachedBundle: Bundle?
    private static var cachedLanguage: String?

    static func text(_ key: String, _ arguments: CVarArg...) -> String {
        let language = UserDefaults.standard.string(forKey: "app.language.preference") ?? "tr"

        let bundle: Bundle
        if let cachedBundle, cachedLanguage == language {
            bundle = cachedBundle
        } else {
            let path = Bundle.main.path(forResource: language, ofType: "lproj")
            if let path {
                bundle = Bundle(path: path) ?? Bundle.main
            } else {
                bundle = Bundle.main
            }
            cachedBundle = bundle
            cachedLanguage = language
        }

        let format = NSLocalizedString(key, bundle: bundle, comment: "")
        guard !arguments.isEmpty else { return format }
        return String(format: format, locale: Locale(identifier: language), arguments: arguments)
    }

    static func invalidateCache() {
        cachedBundle = nil
        cachedLanguage = nil
    }
}
