import Foundation

// MARK: - Fetch Articles Use Case

protocol FetchArticlesUseCaseProtocol {
    func execute(sourceID: String, page: Int, pageSize: Int) async throws -> PaginatedResult<Article>
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

    func execute(sourceID: String, page: Int, pageSize: Int) async throws -> PaginatedResult<Article> {
        let result = try await repository.fetchArticles(sourceID: sourceID, page: page, pageSize: pageSize)
        let sorted = sortingStrategy.newestFirst(result.items)
        return PaginatedResult(
            items: sorted,
            currentPage: result.currentPage,
            hasMorePages: result.hasMorePages
        )
    }
}
