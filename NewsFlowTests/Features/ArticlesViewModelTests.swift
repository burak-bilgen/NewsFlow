import XCTest
@testable import NewsFlow

@MainActor
final class ArticlesViewModelTests: XCTestCase {
    private func makeViewModel(
        articles: Result<[Article], Error> = .success([]),
        readingList: InMemoryReadingListRepositorySpy? = nil,
        errorSimulator: ArticleRequestErrorSimulating? = nil
    ) -> ArticlesViewModel {
        let repository = ArticlesRepositorySpy(result: articles)
        let listRepo = readingList ?? InMemoryReadingListRepositorySpy()
        let simulator = errorSimulator ?? FixedErrorSimulator(results: [false])
        return ArticlesViewModel(
            source: TestFactory.source,
            articlesRepository: repository,
            readingListRepository: listRepo,
            errorSimulator: simulator
        )
    }

    func testInitialStateIsIdle() {
        let viewModel = makeViewModel()
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertTrue(viewModel.articles.isEmpty)
    }

    func testLoadIfNeededSetsLoadedState() async throws {
        let article = TestFactory.article(id: "1", title: "Test", publishedAt: Date())
        let viewModel = makeViewModel(articles: .success([article]))

        await viewModel.loadIfNeeded()

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(viewModel.articles.count, 1)
    }

    func testLoadIfNeededDoesNotReloadIfAlreadyLoaded() async throws {
        let article = TestFactory.article(id: "1", title: "Test", publishedAt: Date())
        let repository = ArticlesRepositorySpy(result: .success([article]))
        let viewModel = ArticlesViewModel(
            source: TestFactory.source,
            articlesRepository: repository,
            readingListRepository: InMemoryReadingListRepositorySpy(),
            errorSimulator: FixedErrorSimulator(results: [false, false])
        )

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        XCTAssertEqual(repository.requestCount, 1)
    }

    func testEmptyArticlesSetEmptyState() async {
        let viewModel = makeViewModel(articles: .success([]))
        await viewModel.loadIfNeeded()
        XCTAssertEqual(viewModel.state, .empty)
    }

    func testNetworkErrorSetsErrorState() async {
        let viewModel = makeViewModel(articles: .failure(NewsAPIError.network))
        await viewModel.loadIfNeeded()

        guard case .error = viewModel.state else {
            return XCTFail("Expected error state")
        }
    }

    func testGenericErrorSetsGenericMessage() async {
        let viewModel = makeViewModel(articles: .failure(NSError(domain: "test", code: 0)))
        await viewModel.loadIfNeeded()

        if case let .error(message) = viewModel.state {
            XCTAssertEqual(message, L10n.text("error.generic"))
        } else {
            XCTFail("Expected error state")
        }
    }

    func testFeaturedArticlesReturnsFirstThree() async throws {
        let articles = (1...5).map {
            TestFactory.article(id: "\($0)", title: "Article \($0)", publishedAt: Date())
        }
        let viewModel = makeViewModel(articles: .success(articles))
        await viewModel.loadIfNeeded()

        XCTAssertEqual(viewModel.featuredArticles.count, 3)
        XCTAssertEqual(viewModel.listArticles.count, 2)
    }

    func testToggleReadingListAddsAndRemoves() async throws {
        let article = TestFactory.article(id: "a1", title: "Test", publishedAt: Date())
        let viewModel = makeViewModel(articles: .success([article]))
        await viewModel.loadIfNeeded()

        XCTAssertFalse(viewModel.isSaved(article))

        await viewModel.toggleReadingList(for: article)
        XCTAssertTrue(viewModel.isSaved(article))

        await viewModel.toggleReadingList(for: article)
        XCTAssertFalse(viewModel.isSaved(article))
    }

    func testPullToRefreshUpdatesArticles() async throws {
        let article1 = TestFactory.article(id: "1", title: "First", publishedAt: Date())
        let repository = ArticlesRepositorySpy(result: .success([article1]))
        let viewModel = ArticlesViewModel(
            source: TestFactory.source,
            articlesRepository: repository,
            readingListRepository: InMemoryReadingListRepositorySpy(),
            errorSimulator: FixedErrorSimulator(results: [false, false])
        )

        await viewModel.loadIfNeeded()
        XCTAssertEqual(viewModel.articles.count, 1)

        await viewModel.pullToRefresh()
        XCTAssertEqual(repository.requestCount, 2)
    }

    func testSimulatedErrorShowsWarningOnPullToRefreshWithExistingArticles() async {
        let article = TestFactory.article(id: "1", title: "Existing", publishedAt: Date())
        let viewModel = ArticlesViewModel(
            source: TestFactory.source,
            articlesRepository: ArticlesRepositorySpy(result: .success([article])),
            readingListRepository: InMemoryReadingListRepositorySpy(),
            errorSimulator: FixedErrorSimulator(results: [false, true])
        )

        await viewModel.loadIfNeeded()
        await viewModel.pullToRefresh()

        XCTAssertNotNil(viewModel.warningMessage)
        XCTAssertEqual(viewModel.state, .loaded)
    }

    func testSimulatedErrorShowsErrorStateWhenNoArticles() async {
        let article = TestFactory.article(id: "1", title: "A", publishedAt: Date())
        let viewModel = ArticlesViewModel(
            source: TestFactory.source,
            articlesRepository: ArticlesRepositorySpy(result: .success([article])),
            readingListRepository: InMemoryReadingListRepositorySpy(),
            errorSimulator: FixedErrorSimulator(results: [true])
        )

        await viewModel.loadIfNeeded()

        guard case .error = viewModel.state else {
            return XCTFail("Expected error state")
        }
    }

    func testRetryRecoversFromError() async {
        let article = TestFactory.article(id: "1", title: "Test", publishedAt: Date())
        let viewModel = ArticlesViewModel(
            source: TestFactory.source,
            articlesRepository: ArticlesRepositorySpy(result: .success([article])),
            readingListRepository: InMemoryReadingListRepositorySpy(),
            errorSimulator: FixedErrorSimulator(results: [true, false])
        )

        await viewModel.loadIfNeeded()
        guard case .error = viewModel.state else { return }

        await viewModel.retry()
        XCTAssertEqual(viewModel.state, .loaded)
    }

    func testStartAndStopAutomaticRefresh() async {
        let viewModel = makeViewModel(articles: .success([
            TestFactory.article(id: "1", title: "A", publishedAt: Date())
        ]))
        await viewModel.loadIfNeeded()

        viewModel.startAutomaticRefresh()
        viewModel.stopAutomaticRefresh()
    }

    func testLoadingSuccessLoadsSavedArticleIDs() async throws {
        let article = TestFactory.article(id: "saved", title: "Saved", publishedAt: Date())
        let readingList = InMemoryReadingListRepositorySpy()
        try await readingList.add(article)
        let viewModel = ArticlesViewModel(
            source: TestFactory.source,
            articlesRepository: ArticlesRepositorySpy(result: .success([article])),
            readingListRepository: readingList,
            errorSimulator: FixedErrorSimulator(results: [false])
        )

        await viewModel.loadIfNeeded()
        XCTAssertTrue(viewModel.isSaved(article))
    }

    func testEveryThirdRequestErrorSimulatorIsDeterministic() async {
        let simulator = EveryThirdRequestErrorSimulator()
        let first = await simulator.shouldSimulateError()
        let second = await simulator.shouldSimulateError()
        let third = await simulator.shouldSimulateError()
        let fourth = await simulator.shouldSimulateError()

        XCTAssertFalse(first)
        XCTAssertFalse(second)
        XCTAssertTrue(third)
        XCTAssertFalse(fourth)

        await simulator.reset()
        let afterReset = await simulator.shouldSimulateError()
        XCTAssertFalse(afterReset)
    }
}
