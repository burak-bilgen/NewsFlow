import Foundation

enum APIConfig {
    private static let apiKeyInfoKey = "NewsAPIKey"

    static var apiKey: String? {
        guard let rawValue = Bundle.main.object(forInfoDictionaryKey: apiKeyInfoKey) as? String else {
            return nil
        }

        let apiKey = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !apiKey.isEmpty, !apiKey.hasPrefix("$(") else {
            return nil
        }

        return apiKey
    }

    static let baseURL = URL(string: "https://newsapi.org")
}
