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
    
    struct GNewsConfig {
        let baseURL: URL?
        let apiKey: String?
        
        static var live: GNewsConfig {
            GNewsConfig(
                baseURL: URL(string: "https://gnews.io/api/v4"),
                apiKey: APIConfig.key(from: "GNewsAPIKey")
            )
        }
    }
    
    struct NewsDataConfig {
        let baseURL: URL?
        let apiKey: String?
        
        static var live: NewsDataConfig {
            NewsDataConfig(
                baseURL: URL(string: "https://newsdata.io/api/1"),
                apiKey: APIConfig.key(from: "NewsDataAPIKey")
            )
        }
    }

    static var guardian: GuardianConfig { .live }
    static var nyt: NYTConfig { .live }
    static var gnews: GNewsConfig { .live }
    static var newsdata: NewsDataConfig { .live }

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

    /// Checks if API keys are configured
    static var hasValidConfiguration: Bool {
        apiKey != nil && guardian.apiKey != nil && nyt.apiKey != nil
    }
}
