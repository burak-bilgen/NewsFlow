import Foundation
@testable import NewsApto

// MARK: - Failing Reading List Repository

actor FailingReadingListRepository: ReadingListRepositoryProtocol {
    func savedArticles() async -> [Article] { [] }
    func savedArticleIDs() async -> Set<String> { [] }
    func isSaved(articleID: String) async -> Bool { false }
    func add(_ article: Article) async throws {
        throw NSError(domain: "test", code: 1)
    }
    func remove(articleID: String) async throws {
        throw NSError(domain: "test", code: 1)
    }
}

// MARK: - Configurable Failure Reading List Repository

actor ConfigurableFailureReadingListRepository: ReadingListRepositoryProtocol {
    private var articles: [String: Article] = [:]
    var shouldFailOnAdd = false
    var shouldFailOnRemove = false

    func savedArticleIDs() async -> Set<String> {
        Set(articles.keys)
    }

    func savedArticles() async -> [Article] {
        articles.values.sorted {
            ($0.publishedAt ?? .distantPast) > ($1.publishedAt ?? .distantPast)
        }
    }

    func isSaved(articleID: String) async -> Bool {
        articles[articleID] != nil
    }

    func add(_ article: Article) async throws {
        if shouldFailOnAdd {
            throw NSError(domain: "test.readingList", code: 100, userInfo: [NSLocalizedDescriptionKey: "Add failed"])
        }
        articles[article.id] = article
    }

    func remove(articleID: String) async throws {
        if shouldFailOnRemove {
            throw NSError(domain: "test.readingList", code: 101, userInfo: [NSLocalizedDescriptionKey: "Remove failed"])
        }
        articles[articleID] = nil
    }
}

// MARK: - Delayed Articles Repository

final class DelayedArticlesRepositorySpy: ArticlesRepositoryProtocol {
    var result: Result<[Article], Error>
    var delayNanoseconds: UInt64
    private(set) var requestCount = 0

    init(result: Result<[Article], Error>, delayNanoseconds: UInt64 = 100_000_000) {
        self.result = result
        self.delayNanoseconds = delayNanoseconds
    }

    func fetchArticles(sourceID: String, page: Int, pageSize: Int) async throws -> PaginatedResult<Article> {
        requestCount += 1
        try await Task.sleep(nanoseconds: delayNanoseconds)
        let items = try result.get()
        return PaginatedResult(
            items: items,
            currentPage: page,
            hasMorePages: items.count >= pageSize
        )
    }

    func fetchAllArticles(page: Int, pageSize: Int) async throws -> PaginatedResult<Article> {
        try await fetchArticles(sourceID: "all", page: page, pageSize: pageSize)
    }
}

// MARK: - Throwing On Specific Page Repository

final class ThrowingOnPageArticlesRepositorySpy: ArticlesRepositoryProtocol {
    private let pageResults: [Int: Result<[Article], Error>]
    private(set) var requestCount = 0
    private(set) var requestedPages: [Int] = []

    init(pageResults: [Int: Result<[Article], Error>]) {
        self.pageResults = pageResults
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

    func fetchAllArticles(page: Int, pageSize: Int) async throws -> PaginatedResult<Article> {
        try await fetchArticles(sourceID: "all", page: page, pageSize: pageSize)
    }
}

// MARK: - Stub NewsAPI Client (reusable across test files)

final class StubNewsAPIClient: NewsAPIClientProtocol {
    private(set) var requestCount = 0
    var handler: ((NewsAPIEndpoint) async throws -> Any)?

    func request<Response: NewsAPIResponseEnvelope>(
        _ responseType: Response.Type,
        endpoint: NewsAPIEndpoint
    ) async throws -> Response {
        requestCount += 1
        if let handler {
            guard let response = try await handler(endpoint) as? Response else {
                throw NewsAPIError.decoding
            }
            return response
        }
        throw NewsAPIError.network
    }
}

// MARK: - Mock URLSession

actor MockURLSession: URLSessionProtocol {
    var result: Result<(Data, URLResponse), Error>

    init(result: Result<(Data, URLResponse), Error>) {
        self.result = result
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try result.get()
    }
}

// MARK: - Stub Clients

struct StubGuardianClient: GuardianClientProtocol {
    let result: Result<[Article], Error>

    func search(query: String?, page: Int, pageSize: Int, section: String?) async throws -> [Article] {
        try result.get()
    }
}

struct StubNYTClient: NYTClientProtocol {
    let result: Result<NYTSearchResult, Error>

    func search(query: String?, page: Int, section: String?) async throws -> NYTSearchResult {
        try result.get()
    }
}
