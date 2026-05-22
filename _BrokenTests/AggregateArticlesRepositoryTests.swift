import XCTest
@testable import NewsApto

final class AggregateArticlesRepositoryTests: XCTestCase {
    func testReturnsFallbackWhenAllSourcesFail() async {
        let failingNewsAPI = StubArticlesRepository(result: .failure(NewsAPIError.network))
        let failingGuardian = StubGuardianClient(result: .failure(NewsAPIError.network))
        let failingNYT = StubNYTClient(result: .failure(NewsAPIError.network))
        let sut = AggregateArticlesRepository(
            newsAPIRepository: failingNewsAPI,
            guardianClient: failingGuardian,
            nytClient: failingNYT
        )

        let result = try? await sut.fetchArticles(sourceID: "all", page: 1, pageSize: 20)

        XCTAssertNotNil(result)
        XCTAssertFalse(result?.items.isEmpty ?? true)
    }
    
    func testMergesResultsFromAllSources() async {
        // Given
        let article1 = Article(id: "1", sourceID: "test", title: "NewsAPI Article")
        let article2 = Article(id: "2", sourceID: "test", title: "Guardian Article")
        let article3 = Article(id: "3", sourceID: "test", title: "NYT Article")
        let newsAPI = StubArticlesRepository(result: .success(PaginatedResult(items: [article1], currentPage: 1, hasMorePages: false)))
        let guardian = StubGuardianClient(result: .success([article2]))
        let nyt = StubNYTClient(result: .success(NYTSearchResult(articles: [article3], hasMore: false)))
        let sut = AggregateArticlesRepository(
            newsAPIRepository: newsAPI,
            guardianClient: guardian,
            nytClient: nyt
        )
        
        // When
        let result = try? await sut.fetchArticles(sourceID: "test", page: 1, pageSize: 20)
        
        // Then
        XCTAssertEqual(result?.items.count, 3)
    }

    func testRemovesDuplicateArticlesByURL() async throws {
        // Given
        let sharedURL = URL(string: "https://example.com/story")!
        let article1 = Article(id: "1", sourceID: "newsapi", title: "Story", url: sharedURL)
        let article2 = Article(id: "2", sourceID: "guardian", title: "Story duplicate", url: sharedURL)
        let article3 = Article(id: "3", sourceID: "nyt", title: "Different", url: URL(string: "https://example.com/other"))
        let newsAPI = StubArticlesRepository(result: .success(PaginatedResult(items: [article1], currentPage: 1, hasMorePages: false)))
        let guardian = StubGuardianClient(result: .success([article2]))
        let nyt = StubNYTClient(result: .success(NYTSearchResult(articles: [article3], hasMore: false)))
        let sut = AggregateArticlesRepository(
            newsAPIRepository: newsAPI,
            guardianClient: guardian,
            nytClient: nyt
        )

        // When
        let result = try await sut.fetchArticles(sourceID: "test", page: 1, pageSize: 20)

        // Then
        XCTAssertEqual(Set(result.items.map(\.id)), Set(["1", "3"]))
    }

    func testBypassingCacheDelegatesToNewsAPICacheBypassingRepository() async throws {
        // Given
        let bypassedArticle = Article(id: "bypassed", sourceID: "test", title: "Bypassed")
        let newsAPI = StubCacheBypassingArticlesRepository(
            normalResult: PaginatedResult(items: [], currentPage: 1, hasMorePages: false),
            bypassResult: PaginatedResult(items: [bypassedArticle], currentPage: 1, hasMorePages: false)
        )
        let guardian = StubGuardianClient(result: .success([]))
        let nyt = StubNYTClient(result: .success(NYTSearchResult(articles: [], hasMore: false)))
        let sut = AggregateArticlesRepository(
            newsAPIRepository: newsAPI,
            guardianClient: guardian,
            nytClient: nyt
        )

        // When
        let result = try await sut.fetchArticlesBypassingCache(sourceID: "test", page: 1, pageSize: 20)

        // Then
        XCTAssertEqual(result.items, [bypassedArticle])
    }
}

// Test doubles
struct StubArticlesRepository: ArticlesRepositoryProtocol {
    let result: Result<PaginatedResult<Article>, Error>
    
    func fetchArticles(sourceID: String, page: Int, pageSize: Int) async throws -> PaginatedResult<Article> {
        try result.get()
    }

    func fetchAllArticles(page: Int, pageSize: Int) async throws -> PaginatedResult<Article> {
        try result.get()
    }
}

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

struct StubCacheBypassingArticlesRepository: ArticlesRepositoryProtocol, CacheBypassing {
    let normalResult: PaginatedResult<Article>
    let bypassResult: PaginatedResult<Article>

    func fetchArticles(sourceID: String, page: Int, pageSize: Int) async throws -> PaginatedResult<Article> {
        normalResult
    }

    func fetchAllArticles(page: Int, pageSize: Int) async throws -> PaginatedResult<Article> {
        normalResult
    }

    func fetchArticlesBypassingCache(sourceID: String, page: Int, pageSize: Int) async throws -> PaginatedResult<Article> {
        bypassResult
    }
}
