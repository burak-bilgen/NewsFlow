import Foundation

protocol PersistentStore {
    func save<T: Encodable>(_ value: T, forKey key: String) async throws
    func load<T: Decodable>(_ type: T.Type, forKey key: String) async -> T?
    func remove(forKey key: String) async
    func lastUpdated(forKey key: String) async -> Date?
}

actor FilePersistentStore: PersistentStore {
    private let fileManager: FileManager
    private let baseURL: URL

    init(fileManager: FileManager = .default) throws {
        self.fileManager = fileManager
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        self.baseURL = urls[0].appendingPathComponent("NewsFlowCache", isDirectory: true)
        try fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
    }

    func save<T: Encodable>(_ value: T, forKey key: String) async throws {
        let url = baseURL.appendingPathComponent("\(key).json")
        let data = try JSONEncoder().encode(value)
        try data.write(to: url)

        let metaURL = baseURL.appendingPathComponent("\(key).meta")
        let meta = ["lastUpdated": ISO8601DateFormatter().string(from: Date())]
        let metaData = try JSONSerialization.data(withJSONObject: meta)
        try metaData.write(to: metaURL)
    }

    func load<T: Decodable>(_ type: T.Type, forKey key: String) async -> T? {
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

actor CachedSourcesRepository: SourcesRepositoryProtocol {
    private let remoteRepository: SourcesRepositoryProtocol
    private let store: PersistentStore
    private let cacheDuration: TimeInterval

    init(
        remoteRepository: SourcesRepositoryProtocol,
        store: PersistentStore,
        cacheDuration: TimeInterval = 300
    ) {
        self.remoteRepository = remoteRepository
        self.store = store
        self.cacheDuration = cacheDuration
    }

    func fetchSources() async throws -> [NewsSource] {
        if let cached: [NewsSource] = await store.load([NewsSource].self, forKey: "sources"),
           let lastUpdated = await store.lastUpdated(forKey: "sources"),
           Date().timeIntervalSince(lastUpdated) < cacheDuration {
            return cached
        }

        let sources = try await remoteRepository.fetchSources()
        try? await store.save(sources, forKey: "sources")
        return sources
    }
}

actor CachedArticlesRepository: ArticlesRepositoryProtocol {
    private let remoteRepository: ArticlesRepositoryProtocol
    private let store: PersistentStore
    private let cacheDuration: TimeInterval

    init(
        remoteRepository: ArticlesRepositoryProtocol,
        store: PersistentStore,
        cacheDuration: TimeInterval = 60
    ) {
        self.remoteRepository = remoteRepository
        self.store = store
        self.cacheDuration = cacheDuration
    }

    func fetchArticles(sourceID: String) async throws -> [Article] {
        let cacheKey = "articles.\(sourceID)"
        if let cached: [Article] = await store.load([Article].self, forKey: cacheKey),
           let lastUpdated = await store.lastUpdated(forKey: cacheKey),
           Date().timeIntervalSince(lastUpdated) < cacheDuration {
            return cached
        }

        let articles = try await remoteRepository.fetchArticles(sourceID: sourceID)
        try? await store.save(articles, forKey: cacheKey)
        return articles
    }
}
