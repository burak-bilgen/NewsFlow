import Foundation
@testable import NewsFlow

// MARK: - Sources Repository Spy

final class SourcesRepositorySpy: SourcesRepositoryProtocol {
    var result: Result<[NewsSource], Error>
    private(set) var requestCount = 0

    init(result: Result<[NewsSource], Error>) {
        self.result = result
    }

    func fetchSources() async throws -> [NewsSource] {
        requestCount += 1
        return try result.get()
    }
}

// MARK: - Articles Repository Spy

final class ArticlesRepositorySpy: ArticlesRepositoryProtocol {
    var result: Result<[Article], Error>
    private(set) var requestCount = 0
    private(set) var lastRequestedPage = 0
    private(set) var lastRequestedPageSize = 0

    init(result: Result<[Article], Error>) {
        self.result = result
    }

    func fetchArticles(sourceID: String, page: Int, pageSize: Int) async throws -> PaginatedResult<Article> {
        requestCount += 1
        lastRequestedPage = page
        lastRequestedPageSize = pageSize
        let items = try result.get()
        return PaginatedResult(
            items: items,
            currentPage: page,
            hasMorePages: items.count >= pageSize
        )
    }
}

// MARK: - Paged Articles Repository Spy (returns different results per page)

final class PagedArticlesRepositorySpy: ArticlesRepositoryProtocol {
    private var pageResults: [Int: Result<[Article], Error>]
    private(set) var requestCount = 0
    private(set) var requestedPages: [Int] = []

    init(pageResults: [Int: Result<[Article], Error>]) {
        self.pageResults = pageResults
    }

    func setResult(_ result: Result<[Article], Error>, forPage page: Int) {
        pageResults[page] = result
    }

    func fetchArticles(sourceID: String, page: Int, pageSize: Int) async throws -> PaginatedResult<Article> {
        requestCount += 1
        requestedPages.append(page)

        guard let result = pageResults[page] else {
            return PaginatedResult(items: [], currentPage: page, hasMorePages: false)
        }

        let items = try result.get()
        return PaginatedResult(
            items: items,
            currentPage: page,
            hasMorePages: items.count >= pageSize
        )
    }
}

// MARK: - In-Memory Reading List Repository Spy

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

// MARK: - Test Factory

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

    static func articles(count: Int, startID: Int = 1, startDate: Date = Date()) -> [Article] {
        (startID..<(startID + count)).map { index in
            article(
                id: "\(index)",
                title: "Article \(index)",
                publishedAt: startDate.addingTimeInterval(-Double(index) * 3600)
            )
        }
    }
}

