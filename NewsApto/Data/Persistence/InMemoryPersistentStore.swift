import Foundation

actor InMemoryPersistentStore: PersistentStore {
    private var storage: [String: Data] = [:]
    private var metadata: [String: Date] = [:]

    func save<T: Encodable & Sendable>(_ value: T, forKey key: String) async throws {
        storage[key] = try JSONEncoder().encode(value)
        metadata[key] = Date()
    }

    func load<T: Decodable & Sendable>(_ type: T.Type, forKey key: String) async -> T? {
        guard let data = storage[key] else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    func remove(forKey key: String) async {
        storage[key] = nil
        metadata[key] = nil
    }

    func removeAll() async {
        storage.removeAll()
        metadata.removeAll()
    }

    func lastUpdated(forKey key: String) async -> Date? {
        metadata[key]
    }
}
