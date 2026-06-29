import Foundation


struct PaginatedResult<T: Sendable>: Sendable {
    let items: [T]
    let currentPage: Int
    let hasMorePages: Bool
}


protocol ArticlesRepositoryProtocol {
    func fetchArticles(sourceID: String, page: Int, pageSize: Int) async throws -> PaginatedResult<Article>
    func fetchAllArticles(page: Int, pageSize: Int) async throws -> PaginatedResult<Article>
}

protocol CacheBypassing {
    func fetchArticlesBypassingCache(sourceID: String, page: Int, pageSize: Int) async throws -> PaginatedResult<Article>
}
