import XCTest
@testable import NewsFlow

// MARK: - FetchArticlesUseCase Tests

@MainActor
final class FetchArticlesUseCaseTests: XCTestCase {
    func testExecuteReturnsSortedArticles() async throws {
        let old = TestFactory.article(id: "1", title: "Old", publishedAt: Date(timeIntervalSince1970: 100))
        let new = TestFactory.article(id: "2", title: "New", publishedAt: Date(timeIntervalSince1970: 200))
        let repo = ArticlesRepositorySpy(result: .success([old, new]))
        let useCase = FetchArticlesUseCase(repository: repo)

        let result = try await useCase.execute(sourceID: "bbc", page: 1, pageSize: 1)

        XCTAssertEqual(result.items.count, 2)
        XCTAssertEqual(result.items.first?.id, "2") // newest first
        XCTAssertTrue(result.hasMorePages)
    }

    func testExecutePropagatesError() async {
        let repo = ArticlesRepositorySpy(result: .failure(NewsAPIError.network))
        let useCase = FetchArticlesUseCase(repository: repo)

        do {
            _ = try await useCase.execute(sourceID: "bbc", page: 1, pageSize: 20)
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(error is NewsAPIError)
        }
    }

    func testExecuteWithEmptyResultSetsNoMorePages() async throws {
        let repo = ArticlesRepositorySpy(result: .success([]))
        let useCase = FetchArticlesUseCase(repository: repo)

        let result = try await useCase.execute(sourceID: "bbc", page: 1, pageSize: 20)

        XCTAssertTrue(result.items.isEmpty)
        XCTAssertFalse(result.hasMorePages)
    }
}

// MARK: - ManageReadingListUseCase Tests

@MainActor
final class ManageReadingListUseCaseTests: XCTestCase {
    func testToggleAddsAndRemoves() async throws {
        let repo = InMemoryReadingListRepositorySpy()
        let useCase = ManageReadingListUseCase(repository: repo)
        let article = TestFactory.article(id: "a1", title: "Test", publishedAt: Date())

        let added = try await useCase.toggle(article)
        XCTAssertTrue(added)
        let saved = await useCase.isSaved(articleID: "a1")
        XCTAssertTrue(saved)

        let removed = try await useCase.toggle(article)
        XCTAssertFalse(removed)
        let notSaved = await useCase.isSaved(articleID: "a1")
        XCTAssertFalse(notSaved)
    }

    func testSavedArticleIDsReturnsSet() async throws {
        let repo = InMemoryReadingListRepositorySpy()
        let useCase = ManageReadingListUseCase(repository: repo)
        let article = TestFactory.article(id: "a1", title: "Test", publishedAt: Date())

        _ = try await useCase.toggle(article)
        let ids = await useCase.savedArticleIDs()

        XCTAssertEqual(ids, Set(["a1"]))
    }
}

// MARK: - FetchSourcesUseCase Tests

@MainActor
final class FetchSourcesUseCaseTests: XCTestCase {
    func testExecuteReturnsSources() async throws {
        let sources = [
            NewsSource(id: "bbc", name: "BBC", description: "A", category: "general", language: "en", url: nil)
        ]
        let repo = SourcesRepositorySpy(result: .success(sources))
        let useCase = FetchSourcesUseCase(repository: repo)

        let result = try await useCase.execute()

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "bbc")
    }

    func testExecutePropagatesError() async {
        let repo = SourcesRepositorySpy(result: .failure(NewsAPIError.network))
        let useCase = FetchSourcesUseCase(repository: repo)

        do {
            _ = try await useCase.execute()
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(error is NewsAPIError)
        }
    }
}

// MARK: - FilterSourcesUseCase Tests

@MainActor
final class FilterSourcesUseCaseTests: XCTestCase {
    private let sources = [
        NewsSource(id: "bbc", name: "BBC", description: "A", category: "general", language: "en", url: nil),
        NewsSource(id: "tc", name: "TechCrunch", description: "B", category: "technology", language: "en", url: nil),
        NewsSource(id: "espn", name: "ESPN", description: "C", category: "sports", language: "en", url: nil)
    ]

    func testExecuteFiltersByCategory() {
        let useCase = FilterSourcesUseCase()
        let result = useCase.execute(sources: sources, selectedCategories: ["technology"])

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "tc")
    }

    func testExecuteReturnsAllWhenNoCategoriesSelected() {
        let useCase = FilterSourcesUseCase()
        let result = useCase.execute(sources: sources, selectedCategories: [])

        XCTAssertEqual(result.count, 3)
    }

    func testExtractCategoriesReturnsSortedUnique() {
        let useCase = FilterSourcesUseCase()
        let categories = useCase.extractCategories(from: sources)

        XCTAssertEqual(categories, ["general", "sports", "technology"])
    }

    func testGroupByCategoryOmitsEmptyGroups() {
        let useCase = FilterSourcesUseCase()
        let grouped = useCase.groupByCategory(sources, categories: ["general", "technology"], selectedCategories: [])

        XCTAssertEqual(grouped.count, 2)
        XCTAssertEqual(grouped[0].category, "general")
        XCTAssertEqual(grouped[1].category, "technology")
    }
}
