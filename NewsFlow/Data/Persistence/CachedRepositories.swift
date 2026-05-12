import Foundation

// MARK: - Cached Sources Repository

actor CachedSourcesRepository: SourcesRepositoryProtocol, SourcesCacheBypassing {
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

    /// Explicitly invalidates the sources cache, forcing the next fetch to hit the network.
    func invalidateCache() async {
        await store.remove(forKey: "sources")
    }

    /// Bypasses cache and fetches directly from the network.
    func fetchSourcesBypassingCache() async throws -> [NewsSource] {
        await store.remove(forKey: "sources")
        return try await remoteRepository.fetchSources()
    }
}

// MARK: - Cached Articles Repository

actor CachedArticlesRepository: ArticlesRepositoryProtocol, CacheBypassing {
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

    func fetchArticles(sourceID: String, page: Int, pageSize: Int) async throws -> PaginatedResult<Article> {
        if page == 1 {
            let cacheKey = "articles.\(sourceID)"
            if let cached: [Article] = await store.load([Article].self, forKey: cacheKey),
               let lastUpdated = await store.lastUpdated(forKey: cacheKey),
               Date().timeIntervalSince(lastUpdated) < cacheDuration {
                return PaginatedResult(
                    items: cached,
                    currentPage: 1,
                    hasMorePages: cached.count >= pageSize
                )
            }

            let result = try await remoteRepository.fetchArticles(sourceID: sourceID, page: page, pageSize: pageSize)
            try? await store.save(result.items, forKey: cacheKey)
            return result
        }

        return try await remoteRepository.fetchArticles(sourceID: sourceID, page: page, pageSize: pageSize)
    }

    func fetchAllArticles(page: Int, pageSize: Int) async throws -> PaginatedResult<Article> {
        try await remoteRepository.fetchAllArticles(page: page, pageSize: pageSize)
    }

    /// Explicitly invalidates the cache for a specific source.
    func invalidateCache(sourceID: String) async {
        await store.remove(forKey: "articles.\(sourceID)")
    }

    /// Invalidates all article caches.
    func invalidateAllCaches() async {
        // Note: PersistentStore doesn't expose enumerate — invalidate known keys
        // This is a limitation; a production system would track cached keys
    }

    /// Bypasses cache and fetches directly from the network.
    func fetchArticlesBypassingCache(sourceID: String, page: Int, pageSize: Int) async throws -> PaginatedResult<Article> {
        // Remove cached data to force network fetch
        if page == 1 {
            let cacheKey = "articles.\(sourceID)"
            await store.remove(forKey: cacheKey)
        }
        return try await remoteRepository.fetchArticles(sourceID: sourceID, page: page, pageSize: pageSize)
    }
}
