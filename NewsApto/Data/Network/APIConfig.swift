import Foundation

enum APIConfig {
    private static let apiKeyInfoKey = "NewsAPIKey"

    static var apiKey: String? {
        key(from: apiKeyInfoKey)
    }

    static let baseURL = URL(string: "https://newsapi.org")

    struct GuardianConfig {
        let baseURL: URL?
        let apiKey: String?

        static var live: GuardianConfig {
            GuardianConfig(
                baseURL: URL(string: "https://content.guardianapis.com"),
                apiKey: APIConfig.key(from: "GuardianAPIKey")
            )
        }
    }

    struct NYTConfig {
        let baseURL: URL?
        let apiKey: String?

        static var live: NYTConfig {
            NYTConfig(
                baseURL: URL(string: "https://api.nytimes.com/svc/search/v2"),
                apiKey: APIConfig.key(from: "NYTAPIKey")
            )
        }
    }

    static var guardian: GuardianConfig { .live }
    static var nyt: NYTConfig { .live }

    private static func key(from infoKey: String) -> String? {
        let plistKey: String? = {
            guard let rawValue = Bundle.main.object(forInfoDictionaryKey: infoKey) as? String else {
                return nil
            }
            let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("$(") else {
                return nil
            }
            return trimmed
        }()

        if let plistKey {
            if let keychainKey = KeychainAPIKeyStore.load(key: infoKey), keychainKey == plistKey {
                return keychainKey
            }
            _ = KeychainAPIKeyStore.save(plistKey, key: infoKey)
            return plistKey
        }

        return KeychainAPIKeyStore.load(key: infoKey)
    }
}
