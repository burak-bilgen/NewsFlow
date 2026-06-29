import Foundation

#if DEBUG


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

    func fetchAllArticles(page: Int, pageSize: Int) async throws -> PaginatedResult<Article> {
        let allArticles = articlesBySource.values.flatMap { $0 }
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


actor InMemoryReadingListRepository: ReadingListRepositoryProtocol {
    private var articles: [String: Article] = [:]

    func savedArticleIDs() async -> Set<String> {
        Set(articles.keys)
    }

    func savedArticles() async -> [Article] {
        articles.values.sorted {
            ($0.publishedAt ?? .distantPast) > ($1.publishedAt ?? .distantPast)
        }
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


final class MockGuardianClient: GuardianClientProtocol {
    func search(query: String?, page: Int, pageSize: Int, section: String?) async throws -> [Article] {
        NewsFixture.articlesBySource.values.flatMap { $0 }
    }
}


final class MockNYTClient: NYTClientProtocol {
    func search(query: String?, page: Int, section: String?) async throws -> NYTSearchResult {
        NYTSearchResult(articles: NewsFixture.articlesBySource.values.flatMap { $0 }, hasMore: false)
    }
}

#endif
