import Foundation

#if DEBUG

// MARK: - Mock Sources Repository

final class MockSourcesRepository: SourcesRepositoryProtocol {
    private let sources: [NewsSource]

    init(sources: [NewsSource]) {
        self.sources = sources
    }

    func fetchSources() async throws -> [NewsSource] {
        sources
    }
}

// MARK: - Mock Articles Repository

final class MockArticlesRepository: ArticlesRepositoryProtocol {
    private let articlesBySource: [String: [Article]]

    init(articlesBySource: [String: [Article]]) {
        self.articlesBySource = articlesBySource
    }

    func fetchArticles(sourceID: String, page: Int, pageSize: Int) async throws -> PaginatedResult<Article> {
        let allArticles = articlesBySource[sourceID] ?? []
        let startIndex = (page - 1) * pageSize
        let endIndex = min(startIndex + pageSize, allArticles.count)

        guard startIndex < allArticles.count else {
            return PaginatedResult(items: [], currentPage: page, hasMorePages: false)
        }

        let items = Array(allArticles[startIndex..<endIndex])
        return PaginatedResult(
            items: items,
            currentPage: page,
            hasMorePages: endIndex < allArticles.count
        )
    }
}

// MARK: - In-Memory Reading List Repository

actor InMemoryReadingListRepository: ReadingListRepositoryProtocol {
    private var articles: [String: Article] = [:]

    func savedArticleIDs() async -> Set<String> {
        Set(articles.keys)
    }

    func isSaved(articleID: String) async -> Bool {
        articles[articleID] != nil
    }

    func add(_ article: Article) async throws {
        articles[article.id] = article
    }

    func remove(articleID: String) async throws {
        articles[articleID] = nil
    }
}

#endif
