import Foundation
@testable import NewsFlow

final class SourcesRepositorySpy: SourcesRepositoryProtocol {
    var result: Result<[NewsSource], Error>

    init(result: Result<[NewsSource], Error>) {
        self.result = result
    }

    func fetchSources() async throws -> [NewsSource] {
        try result.get()
    }
}

final class ArticlesRepositorySpy: ArticlesRepositoryProtocol {
    var result: Result<[Article], Error>
    private(set) var requestCount = 0

    init(result: Result<[Article], Error>) {
        self.result = result
    }

    func fetchArticles(sourceID: String, page: Int, pageSize: Int) async throws -> PaginatedResult<Article> {
        requestCount += 1
        let items = try result.get()
        return PaginatedResult(
            items: items,
            currentPage: page,
            hasMorePages: items.count >= pageSize
        )
    }
}

actor InMemoryReadingListRepositorySpy: ReadingListRepositoryProtocol {
    private var articles: [String: Article] = [:]

    func savedArticleIDs() async -> Set<String> {
        Set(articles.keys)
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

actor FixedErrorSimulator: ArticleRequestErrorSimulating {
    private var results: [Bool]

    init(results: [Bool]) {
        self.results = results
    }

    func shouldSimulateError() async -> Bool {
        guard !results.isEmpty else { return false }
        return results.removeFirst()
    }

    func reset() async {
        results.removeAll()
    }
}

enum TestFactory {
    static let source = NewsSource(
        id: "bbc-news",
        name: "BBC News",
        description: "News source",
        category: "general",
        language: "en",
        url: "https://www.bbc.co.uk/news"
    )

    static func article(id: String, title: String, publishedAt: Date?) -> Article {
        Article(
            id: id,
            sourceID: "bbc-news",
            title: title,
            imageURL: nil,
            publishedAt: publishedAt,
            url: URL(string: "https://example.com/\(id)")
        )
    }
}
