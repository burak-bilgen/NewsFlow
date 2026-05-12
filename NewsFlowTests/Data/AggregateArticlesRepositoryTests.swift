import XCTest
@testable import NewsFlow

final class AggregateArticlesRepositoryTests: XCTestCase {
    func testReturnsEmptyWhenAllSourcesFail() async {
        // Given
        let failingNewsAPI = StubArticlesRepository(result: .failure(NewsAPIError.network))
        let failingGuardian = StubGuardianClient(result: .failure(NewsAPIError.network))
        let failingNYT = StubNYTClient(result: .failure(NewsAPIError.network))
        let sut = AggregateArticlesRepository(
            newsAPIRepository: failingNewsAPI,
            guardianClient: failingGuardian,
            nytClient: failingNYT
        )
        
        // When
        let result = try? await sut.fetchArticles(sourceID: "all", page: 1, pageSize: 20)
        
        // Then
        XCTAssertNil(result)
    }
    
    func testMergesResultsFromAllSources() async {
        // Given
        let article1 = Article(id: "1", sourceID: "test", title: "NewsAPI Article")
        let article2 = Article(id: "2", sourceID: "test", title: "Guardian Article")
        let article3 = Article(id: "3", sourceID: "test", title: "NYT Article")
        let newsAPI = StubArticlesRepository(result: .success(PaginatedResult(items: [article1], currentPage: 1, hasMorePages: false)))
        let guardian = StubGuardianClient(result: .success([article2]))
        let nyt = StubNYTClient(result: .success([article3]))
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
    let result: Result<[Article], Error>
    
    func search(query: String?, page: Int, section: String?) async throws -> [Article] {
        try result.get()
    }
}
