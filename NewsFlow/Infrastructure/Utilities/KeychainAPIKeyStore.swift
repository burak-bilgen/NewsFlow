import Foundation
import Security

// MARK: - Keychain API Key Store

/// Securely stores and retrieves the NewsAPI key from the iOS Keychain.
/// Falls back to Info.plist if no keychain entry exists (first launch).
enum KeychainAPIKeyStore {
    private static func service(for key: String) -> String {
        "burakbilgen.NewsFlow.\(key.lowercased())"
    }

    static func save(_ apiKey: String, key: String = "newsapi-key") -> Bool {
        guard let data = apiKey.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service(for: key),
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        // Delete any existing entry first
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    static func load(key: String = "newsapi-key") -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service(for: key),
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let apiKey = String(data: data, encoding: .utf8),
              !apiKey.isEmpty,
              !apiKey.hasPrefix("$(") else {
            return nil
        }

        return apiKey
    }

    static func delete(key: String = "newsapi-key") -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service(for: key),
            kSecAttrAccount as String: key
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }
}
