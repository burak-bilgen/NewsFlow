import XCTest
@testable import NewsApto

final class FetchFeedUseCaseTests: XCTestCase {
    func testExecuteReturnsScoredSortedArticles() async throws {
        let now = Date()
        let old = Article(id: "1", sourceID: "test", title: "Low scoring older article for testing the sort", publishedAt: now.addingTimeInterval(-86400 * 10))
        let new = Article(id: "2", sourceID: "test", title: "New", imageURL: URL(string: "https://example.com/img.jpg"), publishedAt: now.addingTimeInterval(-1800))
        let repo = ArticlesRepositorySpy(result: .success([old, new]))
        let useCase = FetchFeedUseCase(repository: repo)

        let result = try await useCase.execute(page: 1, pageSize: 20, bypassCache: false)

        XCTAssertEqual(result.items.count, 2)
        XCTAssertEqual(result.items.first?.id, "2")
        XCTAssertEqual(repo.requestCount, 1)
    }

    func testExecutePropagatesError() async {
        let repo = ArticlesRepositorySpy(result: .failure(NewsAPIError.network))
        let useCase = FetchFeedUseCase(repository: repo)

        do {
            _ = try await useCase.execute(page: 1, pageSize: 20, bypassCache: false)
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(error is NewsAPIError)
        }
    }

    func testExecuteBypassCacheWhenRepositorySupportsCacheBypass() async throws {
        let bypassArticle = Article(id: "bypassed", sourceID: "test", title: "Bypassed", publishedAt: Date())
        let normalArticle = Article(id: "normal", sourceID: "test", title: "Normal", publishedAt: Date())
        let repo = StubCacheBypassingArticlesRepository(
            normalResult: PaginatedResult(items: [normalArticle], currentPage: 1, hasMorePages: false),
            bypassResult: PaginatedResult(items: [bypassArticle], currentPage: 1, hasMorePages: false)
        )
        let useCase = FetchFeedUseCase(repository: repo)

        let result = try await useCase.execute(page: 1, pageSize: 20, bypassCache: true)

        XCTAssertEqual(result.items.count, 1)
        XCTAssertEqual(result.items.first?.id, "bypassed")
    }

    func testExecuteNormalPathWhenBypassCacheFalse() async throws {
        let article = Article(id: "normal", sourceID: "test", title: "Normal", publishedAt: Date())
        let repo = StubCacheBypassingArticlesRepository(
            normalResult: PaginatedResult(items: [article], currentPage: 1, hasMorePages: false),
            bypassResult: PaginatedResult(items: [], currentPage: 1, hasMorePages: false)
        )
        let useCase = FetchFeedUseCase(repository: repo)

        let result = try await useCase.execute(page: 1, pageSize: 20, bypassCache: false)

        XCTAssertEqual(result.items.count, 1)
        XCTAssertEqual(result.items.first?.id, "normal")
    }

    func testExecuteHasMorePagesFromRepository() async throws {
        let articles = TestFactory.articles(count: 5)
        let repo = ArticlesRepositorySpy(result: .success(articles))
        let useCase = FetchFeedUseCase(repository: repo)

        let result = try await useCase.execute(page: 1, pageSize: 20, bypassCache: false)

        XCTAssertFalse(result.hasMorePages)
    }

    func testExecuteHasMorePagesWhenFull() async throws {
        let articles = TestFactory.articles(count: 20)
        let repo = ArticlesRepositorySpy(result: .success(articles))
        let useCase = FetchFeedUseCase(repository: repo)

        let result = try await useCase.execute(page: 1, pageSize: 20, bypassCache: false)

        XCTAssertTrue(result.hasMorePages)
    }

    func testExecuteReturnsEmptyResult() async throws {
        let repo = ArticlesRepositorySpy(result: .success([]))
        let useCase = FetchFeedUseCase(repository: repo)

        let result = try await useCase.execute(page: 1, pageSize: 20, bypassCache: false)

        XCTAssertTrue(result.items.isEmpty)
        XCTAssertFalse(result.hasMorePages)
    }
}
