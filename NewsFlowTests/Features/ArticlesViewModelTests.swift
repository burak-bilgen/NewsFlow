import XCTest
@testable import NewsFlow

@MainActor
final class ArticlesViewModelTests: XCTestCase {
    func testLoadingSuccessSortsArticlesAndLoadsSavedState() async throws {
        let savedArticle = TestFactory.article(
            id: "saved",
            title: "Saved",
            publishedAt: Date(timeIntervalSince1970: 20)
        )
        let newestArticle = TestFactory.article(
            id: "new",
            title: "Newest",
            publishedAt: Date(timeIntervalSince1970: 30)
        )
        let repository = ArticlesRepositorySpy(result: .success([savedArticle, newestArticle]))
        let readingList = InMemoryReadingListRepositorySpy()
        try await readingList.add(savedArticle)
        let viewModel = ArticlesViewModel(
            source: TestFactory.source,
            articlesRepository: repository,
            readingListRepository: readingList,
            errorSimulator: FixedErrorSimulator(results: [false])
        )

        await viewModel.loadIfNeeded()

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(viewModel.articles.map(\.id), ["new", "saved"])
        XCTAssertTrue(viewModel.isSaved(savedArticle))
    }

    func testLoadingErrorShowsErrorState() async {
        let viewModel = ArticlesViewModel(
            source: TestFactory.source,
            articlesRepository: ArticlesRepositorySpy(result: .failure(NewsAPIError.network)),
            readingListRepository: InMemoryReadingListRepositorySpy(),
            errorSimulator: FixedErrorSimulator(results: [false])
        )

        await viewModel.loadIfNeeded()

        guard case .error = viewModel.state else {
            return XCTFail("Expected error state")
        }
    }

    func testEveryThirdRequestSimulationIsDeterministic() async {
        let simulator = EveryThirdRequestErrorSimulator()
        let first = await simulator.shouldSimulateError()
        let second = await simulator.shouldSimulateError()
        let third = await simulator.shouldSimulateError()
        let fourth = await simulator.shouldSimulateError()

        XCTAssertFalse(first)
        XCTAssertFalse(second)
        XCTAssertTrue(third)
        XCTAssertFalse(fourth)
    }

    func testRetryAfterSimulatedErrorSendsNewRequestAndRecovers() async {
        let article = TestFactory.article(id: "article", title: "Article", publishedAt: Date())
        let repository = ArticlesRepositorySpy(result: .success([article]))
        let viewModel = ArticlesViewModel(
            source: TestFactory.source,
            articlesRepository: repository,
            readingListRepository: InMemoryReadingListRepositorySpy(),
            errorSimulator: FixedErrorSimulator(results: [false, true, false])
        )

        await viewModel.loadIfNeeded()
        await viewModel.pullToRefresh()

        guard case .loaded = viewModel.state else {
            return XCTFail("Existing articles should remain visible after simulated error")
        }
        XCTAssertEqual(repository.requestCount, 1)

        await viewModel.retry()

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(repository.requestCount, 2)
        XCTAssertNil(viewModel.warningMessage)
    }
}
