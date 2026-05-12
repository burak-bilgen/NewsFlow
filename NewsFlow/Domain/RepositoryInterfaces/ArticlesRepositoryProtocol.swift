import Foundation

// MARK: - Pagination Support

/// Represents a paginated result set with metadata for infinite scrolling.
struct PaginatedResult<T: Sendable>: Sendable {
    let items: [T]
    let currentPage: Int
    let hasMorePages: Bool
}

// MARK: - Repository Protocol

protocol ArticlesRepositoryProtocol {
    func fetchArticles(sourceID: String, page: Int, pageSize: Int) async throws -> PaginatedResult<Article>
}

protocol CacheBypassing {
    func fetchArticlesBypassingCache(sourceID: String, page: Int, pageSize: Int) async throws -> PaginatedResult<Article>
}

protocol ArticleSearchProtocol {
    func searchArticles(query: String, page: Int, pageSize: Int) async throws -> PaginatedResult<Article>
}

protocol CategoryFilterProtocol {
    func fetchArticlesByCategory(_ category: String, page: Int, pageSize: Int) async throws -> PaginatedResult<Article>
}
