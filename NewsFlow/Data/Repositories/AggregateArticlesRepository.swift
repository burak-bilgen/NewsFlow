import Foundation

actor AggregateArticlesRepository: ArticlesRepositoryProtocol {
    private let newsAPIRepository: ArticlesRepositoryProtocol
    private let guardianClient: GuardianClientProtocol
    private let nytClient: NYTClientProtocol

    init(
        newsAPIRepository: ArticlesRepositoryProtocol,
        guardianClient: GuardianClientProtocol,
        nytClient: NYTClientProtocol
    ) {
        self.newsAPIRepository = newsAPIRepository
        self.guardianClient = guardianClient
        self.nytClient = nytClient
    }

    func fetchArticles(sourceID: String, page: Int, pageSize: Int) async throws -> PaginatedResult<Article> {
        async let newsAPIFuture = try? newsAPIRepository.fetchArticles(sourceID: sourceID, page: page, pageSize: pageSize)
        async let guardianFuture = try? guardianClient.search(query: nil, page: page, pageSize: pageSize, section: sourceID == "all" ? nil : sourceID)
        async let nytFuture = try? nytClient.search(query: nil, page: page, section: sourceID == "all" ? nil : sourceID)

        let (newsAPIResult, guardianResult, nytResult) = await (newsAPIFuture, guardianFuture, nytFuture)

        logSourceErrors(newsAPI: newsAPIResult, guardian: guardianResult, nyt: nytResult)

        return merge(newsAPIPaginated: newsAPIResult, guardianArticles: guardianResult, nytArticles: nytResult, page: page)
    }

    func fetchAllArticles(page: Int, pageSize: Int) async throws -> PaginatedResult<Article> {
        async let newsAPIFuture = try? newsAPIRepository.fetchArticles(sourceID: "all", page: page, pageSize: pageSize)
        async let guardianFuture = try? guardianClient.search(query: nil, page: page, pageSize: pageSize * 2, section: nil)
        async let nytFuture = try? nytClient.search(query: nil, page: page, section: nil)

        let (newsAPIResult, guardianResult, nytResult) = await (newsAPIFuture, guardianFuture, nytFuture)

        logSourceErrors(newsAPI: newsAPIResult, guardian: guardianResult, nyt: nytResult)

        return merge(newsAPIPaginated: newsAPIResult, guardianArticles: guardianResult, nytArticles: nytResult, page: page)
    }
}

extension AggregateArticlesRepository: ArticleSearchProtocol {
    func searchArticles(query: String, page: Int, pageSize: Int) async throws -> PaginatedResult<Article> {
        async let newsAPIFuture = try? newsAPIRepository.fetchArticles(sourceID: "all", page: page, pageSize: pageSize)
        async let guardianFuture = try? guardianClient.search(query: query, page: page, pageSize: pageSize, section: nil)
        async let nytFuture = try? nytClient.search(query: query, page: page, section: nil)

        let (newsAPIResult, guardianResult, nytResult) = await (newsAPIFuture, guardianFuture, nytFuture)

        logSourceErrors(newsAPI: newsAPIResult, guardian: guardianResult, nyt: nytResult)

        return merge(newsAPIPaginated: newsAPIResult, guardianArticles: guardianResult, nytArticles: nytResult, page: page)
    }
}

extension AggregateArticlesRepository: CategoryFilterProtocol {
    func fetchArticlesByCategory(_ category: String, page: Int, pageSize: Int) async throws -> PaginatedResult<Article> {
        async let newsAPIFuture = try? newsAPIRepository.fetchArticles(sourceID: category, page: page, pageSize: pageSize)
        async let guardianFuture = try? guardianClient.search(query: nil, page: page, pageSize: pageSize, section: category)
        async let nytFuture = try? nytClient.search(query: nil, page: page, section: category)

        let (newsAPIResult, guardianResult, nytResult) = await (newsAPIFuture, guardianFuture, nytFuture)

        logSourceErrors(newsAPI: newsAPIResult, guardian: guardianResult, nyt: nytResult)

        return merge(newsAPIPaginated: newsAPIResult, guardianArticles: guardianResult, nytArticles: nytResult, page: page)
    }
}

private extension AggregateArticlesRepository {
    func logSourceErrors(newsAPI: PaginatedResult<Article>?, guardian: [Article]?, nyt: [Article]?) {
        if newsAPI == nil { NewsFlowLogger.shared.error("NewsAPI source failed", category: "Repository") }
        if guardian == nil { NewsFlowLogger.shared.error("Guardian source failed", category: "Repository") }
        if nyt == nil { NewsFlowLogger.shared.error("NYT source failed", category: "Repository") }
    }

    func merge(newsAPIPaginated: PaginatedResult<Article>?, guardianArticles: [Article]?, nytArticles: [Article]?, page: Int) -> PaginatedResult<Article> {
        var allArticles: [Article] = []
        var hasMore = false

        if let paginated = newsAPIPaginated {
            allArticles.append(contentsOf: paginated.items)
            if paginated.hasMorePages { hasMore = true }
        }

        if let articles = guardianArticles {
            allArticles.append(contentsOf: articles)
            hasMore = true
        }

        if let articles = nytArticles {
            allArticles.append(contentsOf: articles)
            hasMore = true
        }

        allArticles.sort { ($0.publishedAt ?? .distantPast) > ($1.publishedAt ?? .distantPast) }

        if allArticles.isEmpty {
            NewsFlowLogger.shared.info("All sources returned empty — nothing to show", category: "Repository")
        }

        return PaginatedResult(
            items: allArticles,
            currentPage: page,
            hasMorePages: hasMore
        )
    }
}
