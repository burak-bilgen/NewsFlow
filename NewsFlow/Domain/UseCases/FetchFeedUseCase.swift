import Foundation

protocol FetchFeedUseCaseProtocol {
    func execute(page: Int, pageSize: Int, bypassCache: Bool) async throws -> PaginatedResult<Article>
}

final class FetchFeedUseCase: FetchFeedUseCaseProtocol {
    private let repository: ArticlesRepositoryProtocol
    private let scorer: SmartArticleScorer

    init(
        repository: ArticlesRepositoryProtocol,
        scorer: SmartArticleScorer = SmartArticleScorer()
    ) {
        self.repository = repository
        self.scorer = scorer
    }

    func execute(page: Int, pageSize: Int, bypassCache: Bool = false) async throws -> PaginatedResult<Article> {
        if bypassCache, let cacheBypassingRepo = repository as? CacheBypassing {
            let result = try await cacheBypassingRepo.fetchArticlesBypassingCache(sourceID: "all", page: page, pageSize: pageSize)
            let sorted = scorer.sortAndDeduplicate(result.items)
            return PaginatedResult(
                items: sorted,
                currentPage: result.currentPage,
                hasMorePages: result.hasMorePages
            )
        }

        let result = try await repository.fetchAllArticles(page: page, pageSize: pageSize)
        let sorted = scorer.sortAndDeduplicate(result.items)
        return PaginatedResult(
            items: sorted,
            currentPage: result.currentPage,
            hasMorePages: result.hasMorePages
        )
    }
}
