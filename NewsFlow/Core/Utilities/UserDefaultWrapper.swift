import Combine
import Foundation

/// A thread-safe property wrapper that persists values to `UserDefaults`.
///
/// Demonstrates advanced Swift features: property wrappers, generics with constraints,
/// and `UserDefaults` observation via KVO-compatible key paths.
///
/// ```swift
/// @UserDefault("selectedTheme", defaultValue: AppTheme.system)
/// var selectedTheme: AppTheme
/// ```
@propertyWrapper
struct UserDefault<Value: Codable> {
    let key: String
    let defaultValue: Value
    private let userDefaults: UserDefaults
    private let notificationName: Notification.Name

    init(
        _ key: String,
        defaultValue: Value,
        userDefaults: UserDefaults = .standard
    ) {
        self.key = key
        self.defaultValue = defaultValue
        self.userDefaults = userDefaults
        self.notificationName = Notification.Name("UserDefault.didChange.\(key)")
    }

    var wrappedValue: Value {
        get {
            guard let data = userDefaults.data(forKey: key) else {
                return defaultValue
            }
            return (try? JSONDecoder().decode(Value.self, from: data)) ?? defaultValue
        }
        nonmutating set {
            if let data = try? JSONEncoder().encode(newValue) {
                userDefaults.set(data, forKey: key)
                userDefaults.synchronize()
                NotificationCenter.default.post(name: notificationName, object: nil)
            }
        }
    }

    var projectedValue: AnyPublisher<Value, Never> {
        NotificationCenter.default
            .publisher(for: notificationName)
            .map { _ in self.wrappedValue }
            .prepend(wrappedValue)
            .eraseToAnyPublisher()
    }
}
