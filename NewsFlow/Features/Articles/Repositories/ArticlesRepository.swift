import Foundation

protocol ArticlesRepositoryProtocol {
    func fetchArticles(sourceID: String) async throws -> [Article]
}

final class NewsAPIArticlesRepository: ArticlesRepositoryProtocol {
    private let client: NewsAPIClientProtocol

    init(client: NewsAPIClientProtocol) {
        self.client = client
    }

    func fetchArticles(sourceID: String) async throws -> [Article] {
        let response = try await client.request(
            ArticlesResponseDTO.self,
            endpoint: .topHeadlines(sourceID: sourceID)
        )

        return ArticleSorter().newestFirst(response.articles.compactMap { $0.domainModel(fallbackSourceID: sourceID) })
    }
}

protocol ArticleSorting {
    func newestFirst(_ articles: [Article]) -> [Article]
}

struct ArticleSorter: ArticleSorting {
    func newestFirst(_ articles: [Article]) -> [Article] {
        articles.sorted { lhs, rhs in
            switch (lhs.publishedAt, rhs.publishedAt) {
            case let (left?, right?):
                return left > right
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
        }
    }
}
