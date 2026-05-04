import Foundation

// MARK: - Pagination Support

/// Represents a paginated result set with metadata for infinite scrolling.
struct PaginatedResult<T> {
    let items: [T]
    let currentPage: Int
    let hasMorePages: Bool
}

// MARK: - Repository Protocol

protocol ArticlesRepositoryProtocol {
    func fetchArticles(sourceID: String, page: Int, pageSize: Int) async throws -> PaginatedResult<Article>
}

// MARK: - NewsAPI Implementation

final class NewsAPIArticlesRepository: ArticlesRepositoryProtocol {
    private let client: NewsAPIClientProtocol
    private let pageSize: Int

    init(client: NewsAPIClientProtocol, pageSize: Int = 20) {
        self.client = client
        self.pageSize = pageSize
    }

    func fetchArticles(sourceID: String, page: Int, pageSize: Int) async throws -> PaginatedResult<Article> {
        let response = try await client.request(
            ArticlesResponseDTO.self,
            endpoint: .topHeadlines(sourceID: sourceID, page: page, pageSize: pageSize)
        )

        let articles = ArticleSorter().newestFirst(
            response.articles.compactMap { $0.domainModel(fallbackSourceID: sourceID) }
        )

        // NewsAPI returns max 100 results; if we got a full page, assume more exist
        let hasMore = articles.count >= pageSize

        return PaginatedResult(
            items: articles,
            currentPage: page,
            hasMorePages: hasMore
        )
    }
}
