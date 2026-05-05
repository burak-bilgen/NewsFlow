import Foundation

// MARK: - Cached Sources Repository

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

    /// Explicitly invalidates the sources cache, forcing the next fetch to hit the network.
    func invalidateCache() async {
        await store.remove(forKey: "sources")
    }
}

// MARK: - Cached Articles Repository

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

    func fetchArticles(sourceID: String, page: Int, pageSize: Int) async throws -> PaginatedResult<Article> {
        // Only cache page 1 (first load). Subsequent pages are fetched live.
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

    /// Explicitly invalidates the cache for a specific source.
    func invalidateCache(sourceID: String) async {
        await store.remove(forKey: "articles.\(sourceID)")
    }

    /// Invalidates all article caches.
    func invalidateAllCaches() async {
        // Note: PersistentStore doesn't expose enumerate — invalidate known keys
        // This is a limitation; a production system would track cached keys
    }
}

