import Foundation

protocol PersistentStore {
    func save<T: Encodable & Sendable>(_ value: T, forKey key: String) async throws
    func load<T: Decodable & Sendable>(_ type: T.Type, forKey key: String) async -> T?
    func remove(forKey key: String) async
    func lastUpdated(forKey key: String) async -> Date?
}

actor FilePersistentStore: PersistentStore {
    private let fileManager: FileManager
    private let baseURL: URL

    init(fileManager: FileManager = .default, baseURL: URL? = nil) throws {
        self.fileManager = fileManager
        if let baseURL {
            self.baseURL = baseURL
        } else {
            let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
            self.baseURL = urls[0].appendingPathComponent("NewsAptoCache", isDirectory: true)
        }
        try fileManager.createDirectory(at: self.baseURL, withIntermediateDirectories: true)
    }

    func save<T: Encodable & Sendable>(_ value: T, forKey key: String) async throws {
        let url = baseURL.appendingPathComponent("\(key).json")
        let data = try JSONEncoder().encode(value)
        try data.write(to: url)

        let metaURL = baseURL.appendingPathComponent("\(key).meta")
        let meta = ["lastUpdated": ISO8601DateFormatter().string(from: Date())]
        let metaData = try JSONSerialization.data(withJSONObject: meta)
        try metaData.write(to: metaURL)
    }

    func load<T: Decodable & Sendable>(_ type: T.Type, forKey key: String) async -> T? {
        let url = baseURL.appendingPathComponent("\(key).json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    func remove(forKey key: String) async {
        let url = baseURL.appendingPathComponent("\(key).json")
        let metaURL = baseURL.appendingPathComponent("\(key).meta")
        try? fileManager.removeItem(at: url)
        try? fileManager.removeItem(at: metaURL)
    }

    func lastUpdated(forKey key: String) async -> Date? {
        let metaURL = baseURL.appendingPathComponent("\(key).meta")
        guard let data = try? Data(contentsOf: metaURL),
              let meta = try? JSONSerialization.jsonObject(with: data) as? [String: String],
              let dateString = meta["lastUpdated"] else { return nil }
        return ISO8601DateFormatter().date(from: dateString)
    }
}
