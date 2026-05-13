import Foundation

// MARK: - Fetch Articles Use Case

protocol FetchArticlesUseCaseProtocol {
    func execute(sourceID: String, page: Int, pageSize: Int, bypassCache: Bool) async throws -> PaginatedResult<Article>
    func searchArticles(query: String, page: Int, pageSize: Int) async throws -> PaginatedResult<Article>
}

final class FetchArticlesUseCase: FetchArticlesUseCaseProtocol {
    private let repository: ArticlesRepositoryProtocol
    private let sortingStrategy: ArticleSorting

    init(
        repository: ArticlesRepositoryProtocol,
        sortingStrategy: ArticleSorting = ArticleSorter()
    ) {
        self.repository = repository
        self.sortingStrategy = sortingStrategy
    }

    func execute(sourceID: String, page: Int, pageSize: Int, bypassCache: Bool = false) async throws -> PaginatedResult<Article> {
        if bypassCache, let cacheBypassingRepo = repository as? CacheBypassing {
            let result = try await cacheBypassingRepo.fetchArticlesBypassingCache(sourceID: sourceID, page: page, pageSize: pageSize)
            let sorted = sortingStrategy.newestFirst(result.items)
            return PaginatedResult(
                items: sorted,
                currentPage: result.currentPage,
                hasMorePages: result.hasMorePages
            )
        }
        
        let result = try await repository.fetchArticles(sourceID: sourceID, page: page, pageSize: pageSize)
        let sorted = sortingStrategy.newestFirst(result.items)
        return PaginatedResult(
            items: sorted,
            currentPage: result.currentPage,
            hasMorePages: result.hasMorePages
        )
    }

    func searchArticles(query: String, page: Int, pageSize: Int) async throws -> PaginatedResult<Article> {
        guard let searchableRepo = repository as? ArticleSearchProtocol else {
            NewsAptoLogger.shared.error("Repository does not support search", category: "UseCase")
            throw NewsAPIError.searchNotSupported
        }
        let result = try await searchableRepo.searchArticles(query: query, page: page, pageSize: pageSize)
        let sorted = sortingStrategy.newestFirst(result.items)
        NewsAptoLogger.shared.debug("Search returned \(sorted.count) articles (page \(page))", category: "UseCase")
        return PaginatedResult(
            items: sorted,
            currentPage: result.currentPage,
            hasMorePages: result.hasMorePages
        )
    }
}
