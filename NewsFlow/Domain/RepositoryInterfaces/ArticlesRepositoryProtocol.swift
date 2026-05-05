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
