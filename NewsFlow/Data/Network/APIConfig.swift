import Foundation

enum APIConfig {
    private static let apiKeyInfoKey = "NewsAPIKey"

    static var apiKey: String? {
        // 1. Try Keychain first (most secure, persists across reinstalls)
        if let keychainKey = KeychainAPIKeyStore.load() {
            return keychainKey
        }

        // 2. Fall back to Info.plist (first launch or development)
        guard let rawValue = Bundle.main.object(forInfoDictionaryKey: apiKeyInfoKey) as? String else {
            return nil
        }

        let apiKey = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !apiKey.isEmpty, !apiKey.hasPrefix("$(") else {
            return nil
        }

        // 3. Migrate to Keychain for future launches
        _ = KeychainAPIKeyStore.save(apiKey)

        return apiKey
    }

    static let baseURL = URL(string: "https://newsapi.org")
}
