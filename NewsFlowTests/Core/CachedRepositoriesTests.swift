import XCTest
@testable import NewsFlow

// MARK: - Mock Persistent Store

actor MockPersistentStore: PersistentStore {
    var storage: [String: Data] = [:]
    var meta: [String: Date] = [:]

    func save<T: Encodable>(_ value: T, forKey key: String) async throws {
        let data = try JSONEncoder().encode(value)
        storage[key] = data
        meta[key] = Date()
    }

    func load<T: Decodable>(_ type: T.Type, forKey key: String) async -> T? {
        guard let data = storage[key] else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    func remove(forKey key: String) async {
        storage.removeValue(forKey: key)
        meta.removeValue(forKey: key)
    }

    func lastUpdated(forKey key: String) async -> Date? {
        meta[key]
    }
}

// MARK: - Cached Repositories Tests

final class CachedRepositoriesTests: XCTestCase {

    // MARK: CachedSourcesRepository

    func testFetchSourcesReturnsRemoteDataWhenCacheEmpty() async throws {
        let source = NewsSource(
            id: "bbc",
            name: "BBC",
            description: "News",
            category: "general",
            language: "en",
            url: nil
        )
        let remote = SourcesRepositorySpy(result: .success([source]))
        let store = MockPersistentStore()
        let cached = CachedSourcesRepository(remoteRepository: remote, store: store, cacheDuration: 300)

        let result = try await cached.fetchSources()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "bbc")
    }

    func testFetchSourcesReturnsCachedDataWhenFresh() async throws {
        let source = NewsSource(
            id: "bbc",
            name: "BBC",
            description: "News",
            category: "general",
            language: "en",
            url: nil
        )
        let remote = SourcesRepositorySpy(result: .success([source]))
        let store = MockPersistentStore()
        let cached = CachedSourcesRepository(remoteRepository: remote, store: store, cacheDuration: 300)

        // First fetch hits remote and populates cache
        _ = try await cached.fetchSources()

        // Second fetch with empty remote proves cache is used
        let emptyRemote = SourcesRepositorySpy(result: .success([]))
        let cached2 = CachedSourcesRepository(remoteRepository: emptyRemote, store: store, cacheDuration: 300)
        let result = try await cached2.fetchSources()

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "bbc")
    }

    func testFetchSourcesHitsRemoteWhenCacheExpired() async throws {
        let source = NewsSource(
            id: "bbc",
            name: "BBC",
            description: "News",
            category: "general",
            language: "en",
            url: nil
        )
        let remote = SourcesRepositorySpy(result: .success([source]))
        let store = MockPersistentStore()
        let cached = CachedSourcesRepository(remoteRepository: remote, store: store, cacheDuration: -1)

        // Pre-populate expired cache
        try await store.save([source], forKey: "sources")

        let result = try await cached.fetchSources()
        XCTAssertEqual(result.count, 1)
    }

    func testFetchSourcesSavesToCacheAfterRemoteFetch() async throws {
        let source = NewsSource(
            id: "cnn",
            name: "CNN",
            description: "News",
            category: "general",
            language: "en",
            url: nil
        )
        let remote = SourcesRepositorySpy(result: .success([source]))
        let store = MockPersistentStore()
        let cached = CachedSourcesRepository(remoteRepository: remote, store: store, cacheDuration: 300)

        _ = try await cached.fetchSources()

        let cachedData: [NewsSource]? = await store.load([NewsSource].self, forKey: "sources")
        XCTAssertEqual(cachedData?.first?.id, "cnn")
    }

    // MARK: CachedArticlesRepository

    func testFetchArticlesCachesPageOne() async throws {
        let article = TestFactory.article(id: "1", title: "Test", publishedAt: Date())
        let remote = ArticlesRepositorySpy(result: .success([article]))
        let store = MockPersistentStore()
        let cached = CachedArticlesRepository(remoteRepository: remote, store: store, cacheDuration: 60)

        let result = try await cached.fetchArticles(sourceID: "bbc", page: 1, pageSize: 20)
        XCTAssertEqual(result.items.count, 1)

        // Second fetch with empty remote proves cache is used for page 1
        let emptyRemote = ArticlesRepositorySpy(result: .success([]))
        let cached2 = CachedArticlesRepository(remoteRepository: emptyRemote, store: store, cacheDuration: 60)
        let result2 = try await cached2.fetchArticles(sourceID: "bbc", page: 1, pageSize: 20)

        XCTAssertEqual(result2.items.count, 1)
        XCTAssertEqual(result2.items.first?.id, "1")
    }

    func testFetchArticlesDoesNotCacheBeyondPageOne() async throws {
        let article = TestFactory.article(id: "1", title: "Test", publishedAt: Date())
        let remote = ArticlesRepositorySpy(result: .success([article]))
        let store = MockPersistentStore()
        let cached = CachedArticlesRepository(remoteRepository: remote, store: store, cacheDuration: 60)

        let result = try await cached.fetchArticles(sourceID: "bbc", page: 2, pageSize: 20)
        XCTAssertEqual(result.items.count, 1)
        XCTAssertEqual(remote.requestCount, 1)

        let result2 = try await cached.fetchArticles(sourceID: "bbc", page: 2, pageSize: 20)
        XCTAssertEqual(result2.items.count, 1)
        XCTAssertEqual(remote.requestCount, 2)
    }

    func testFetchArticlesSetsHasMorePagesBasedOnCacheCount() async throws {
        let articles = (1...5).map {
            TestFactory.article(id: "\($0)", title: "Article \($0)", publishedAt: Date())
        }
        let remote = ArticlesRepositorySpy(result: .success(articles))
        let store = MockPersistentStore()
        let cached = CachedArticlesRepository(remoteRepository: remote, store: store, cacheDuration: 60)

        let result = try await cached.fetchArticles(sourceID: "bbc", page: 1, pageSize: 3)
        XCTAssertTrue(result.hasMorePages)
    }
}
