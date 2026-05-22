import Foundation

actor CachedArticlesRepository: ArticlesRepositoryProtocol, CacheBypassing {
    private let remoteRepository: ArticlesRepositoryProtocol
    private let store: PersistentStore
    private let cacheDuration: TimeInterval
    private var inflightFetches: [String: Task<PaginatedResult<Article>, Error>] = [:]

    init(
        remoteRepository: ArticlesRepositoryProtocol,
        store: PersistentStore,
        cacheDuration: TimeInterval = 300
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

            if let existing = inflightFetches[cacheKey] {
                return try await existing.value
            }

            let task = Task<PaginatedResult<Article>, Error> {
                defer { inflightFetches.removeValue(forKey: cacheKey) }
                let result = try await remoteRepository.fetchArticles(sourceID: sourceID, page: page, pageSize: pageSize)
                try? await store.save(result.items, forKey: cacheKey)
                return result
            }
            inflightFetches[cacheKey] = task
            return try await task.value
        }

        return try await remoteRepository.fetchArticles(sourceID: sourceID, page: page, pageSize: pageSize)
    }

    func fetchAllArticles(page: Int, pageSize: Int) async throws -> PaginatedResult<Article> {
        if page == 1 {
            let cacheKey = "articles.feed"
            if let cached: [Article] = await store.load([Article].self, forKey: cacheKey),
               let lastUpdated = await store.lastUpdated(forKey: cacheKey),
               Date().timeIntervalSince(lastUpdated) < cacheDuration {
                return PaginatedResult(
                    items: cached,
                    currentPage: 1,
                    hasMorePages: cached.count >= pageSize
                )
            }

            if let existing = inflightFetches[cacheKey] {
                return try await existing.value
            }

            let task = Task<PaginatedResult<Article>, Error> {
                defer { inflightFetches.removeValue(forKey: cacheKey) }
                let result = try await remoteRepository.fetchAllArticles(page: page, pageSize: pageSize)
                try? await store.save(result.items, forKey: cacheKey)
                return result
            }
            inflightFetches[cacheKey] = task
            return try await task.value
        }

        return try await remoteRepository.fetchAllArticles(page: page, pageSize: pageSize)
    }

    func invalidateCache(sourceID: String) async {
        await store.remove(forKey: "articles.\(sourceID)")
    }

    func invalidateAllCaches() async {
        await store.removeAll()
    }

    func fetchArticlesBypassingCache(sourceID: String, page: Int, pageSize: Int) async throws -> PaginatedResult<Article> {
        if page == 1 {
            let cacheKey = "articles.\(sourceID)"
            await store.remove(forKey: cacheKey)
        }
        return try await remoteRepository.fetchArticles(sourceID: sourceID, page: page, pageSize: pageSize)
    }
}
