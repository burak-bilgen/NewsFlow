import Foundation

enum L10n {
    static func text(_ key: String, _ arguments: CVarArg...) -> String {
        let language = UserDefaults.standard.string(forKey: "app.language.preference") ?? "tr"
        let path = Bundle.main.path(forResource: language, ofType: "lproj")
        let bundle: Bundle
        if let path {
            bundle = Bundle(path: path) ?? Bundle.main
        } else {
            bundle = Bundle.main
        }

        let format = NSLocalizedString(key, bundle: bundle, comment: "")
        guard !arguments.isEmpty else { return format }
        return String(format: format, locale: Locale(identifier: language), arguments: arguments)
    }
}
