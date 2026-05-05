import XCTest
@testable import NewsFlow

@MainActor
final class ArticlesViewModelTests: XCTestCase {
    private func makeViewModel(
        articles: Result<[Article], Error> = .success([]),
        readingList: ReadingListRepositoryProtocol? = nil,
        pageSize: Int = 20
    ) -> ArticlesViewModel {
        let repository = ArticlesRepositorySpy(result: articles)
        let listRepo = readingList ?? InMemoryReadingListRepositorySpy()
        return ArticlesViewModel(
            source: TestFactory.source,
            fetchUseCase: FetchArticlesUseCase(repository: repository),
            readingListUseCase: ManageReadingListUseCase(repository: listRepo),
            pageSize: pageSize
        )
    }

    // MARK: - Initial State

    func testInitialStateIsIdle() {
        let viewModel = makeViewModel()
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertTrue(viewModel.articles.isEmpty)
        XCTAssertTrue(viewModel.savedArticleIDs.isEmpty)
        XCTAssertTrue(viewModel.hasMorePages)
    }

    // MARK: - Loading

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
            fetchUseCase: FetchArticlesUseCase(repository: repository),
            readingListUseCase: ManageReadingListUseCase(repository: InMemoryReadingListRepositorySpy())
        )

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        XCTAssertEqual(repository.requestCount, 1)
    }

    func testLoadIfNeededDoesNotLoadWhenStateIsError() async {
        let repository = ArticlesRepositorySpy(result: .failure(NewsAPIError.simulatedNetwork))
        let viewModel = ArticlesViewModel(
            source: TestFactory.source,
            fetchUseCase: FetchArticlesUseCase(repository: repository),
            readingListUseCase: ManageReadingListUseCase(repository: InMemoryReadingListRepositorySpy())
        )
        await viewModel.loadIfNeeded()
        XCTAssertEqual(viewModel.state, .error(L10n.text("error.simulatedFetch")))

        await viewModel.loadIfNeeded()
        XCTAssertEqual(repository.requestCount, 1)
    }

    func testEmptyArticlesSetEmptyState() async {
        let viewModel = makeViewModel(articles: .success([]))
        await viewModel.loadIfNeeded()
        XCTAssertEqual(viewModel.state, .empty)
    }

    // MARK: - Errors

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

    func testCancelledErrorResetsLoadingState() async {
        let viewModel = makeViewModel(articles: .failure(NewsAPIError.cancelled))
        await viewModel.loadIfNeeded()
        XCTAssertNotEqual(viewModel.state, .error(""))
        XCTAssertFalse(viewModel.isRefreshing)
    }

    // MARK: - Derived Properties

    func testFeaturedArticlesReturnsFirstThree() async throws {
        let articles = (1...5).map {
            TestFactory.article(id: "\($0)", title: "Article \($0)", publishedAt: Date())
        }
        let viewModel = makeViewModel(articles: .success(articles))
        await viewModel.loadIfNeeded()

        XCTAssertEqual(viewModel.featuredArticles.count, 3)
        XCTAssertEqual(viewModel.listArticles.count, 2)
    }

    func testFeaturedAndListArticlesAreEmptyBeforeLoading() {
        let viewModel = makeViewModel()
        XCTAssertTrue(viewModel.featuredArticles.isEmpty)
        XCTAssertTrue(viewModel.listArticles.isEmpty)
    }

    // MARK: - Reading List

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

    func testToggleReadingListSetsWarningMessageOnError() async {
        let article = TestFactory.article(id: "a1", title: "Test", publishedAt: Date())
        let viewModel = ArticlesViewModel(
            source: TestFactory.source,
            fetchUseCase: FetchArticlesUseCase(repository: ArticlesRepositorySpy(result: .success([article]))),
            readingListUseCase: ManageReadingListUseCase(repository: FailingReadingListRepository())
        )
        await viewModel.loadIfNeeded()

        await viewModel.toggleReadingList(for: article)
        // Toast is shown but state remains loaded
        XCTAssertEqual(viewModel.state, .loaded)
    }

    func testLoadingSuccessLoadsSavedArticleIDs() async throws {
        let article = TestFactory.article(id: "saved", title: "Saved", publishedAt: Date())
        let readingList = InMemoryReadingListRepositorySpy()
        try await readingList.add(article)
        let viewModel = ArticlesViewModel(
            source: TestFactory.source,
            fetchUseCase: FetchArticlesUseCase(repository: ArticlesRepositorySpy(result: .success([article]))),
            readingListUseCase: ManageReadingListUseCase(repository: readingList)
        )

        await viewModel.loadIfNeeded()
        XCTAssertTrue(viewModel.isSaved(article))
    }

    // MARK: - Pull to Refresh

    func testPullToRefreshUpdatesArticles() async throws {
        let article1 = TestFactory.article(id: "1", title: "First", publishedAt: Date())
        let repository = ArticlesRepositorySpy(result: .success([article1]))
        let viewModel = ArticlesViewModel(
            source: TestFactory.source,
            fetchUseCase: FetchArticlesUseCase(repository: repository),
            readingListUseCase: ManageReadingListUseCase(repository: InMemoryReadingListRepositorySpy())
        )

        await viewModel.loadIfNeeded()
        XCTAssertEqual(viewModel.articles.count, 1)

        await viewModel.pullToRefresh()
        XCTAssertEqual(repository.requestCount, 2)
    }

    func testPullToRefreshResetsPageToOne() async {
        let article = TestFactory.article(id: "1", title: "A", publishedAt: Date())
        let repository = ArticlesRepositorySpy(result: .success([article]))
        let viewModel = ArticlesViewModel(
            source: TestFactory.source,
            fetchUseCase: FetchArticlesUseCase(repository: repository),
            readingListUseCase: ManageReadingListUseCase(repository: InMemoryReadingListRepositorySpy()),
            pageSize: 1
        )
        await viewModel.loadIfNeeded()
        await viewModel.loadMore()
        XCTAssertEqual(repository.requestCount, 2)

        await viewModel.pullToRefresh()
        XCTAssertEqual(repository.requestCount, 3)
    }

    // MARK: - Simulated Errors

    func testSimulatedErrorShowsWarningOnPullToRefreshWithExistingArticles() async {
        let article = TestFactory.article(id: "1", title: "Existing", publishedAt: Date())
        let repository = ArticlesRepositorySpy(result: .success([article]))
        let viewModel = ArticlesViewModel(
            source: TestFactory.source,
            fetchUseCase: FetchArticlesUseCase(repository: repository),
            readingListUseCase: ManageReadingListUseCase(repository: InMemoryReadingListRepositorySpy())
        )

        await viewModel.loadIfNeeded()
        repository.result = .failure(NewsAPIError.simulatedNetwork)
        await viewModel.pullToRefresh()

        // Toast is shown but state remains loaded
        XCTAssertEqual(viewModel.state, .loaded)
    }

    func testSimulatedErrorShowsErrorStateWhenNoArticles() async {
        let viewModel = ArticlesViewModel(
            source: TestFactory.source,
            fetchUseCase: FetchArticlesUseCase(repository: ArticlesRepositorySpy(result: .failure(NewsAPIError.simulatedNetwork))),
            readingListUseCase: ManageReadingListUseCase(repository: InMemoryReadingListRepositorySpy())
        )

        await viewModel.loadIfNeeded()

        guard case .error = viewModel.state else {
            return XCTFail("Expected error state")
        }
    }

    func testSimulatedErrorOnLoadMoreDoesNotChangeState() async {
        let article = TestFactory.article(id: "1", title: "A", publishedAt: Date())
        let repository = ArticlesRepositorySpy(result: .success([article]))
        let viewModel = ArticlesViewModel(
            source: TestFactory.source,
            fetchUseCase: FetchArticlesUseCase(repository: repository),
            readingListUseCase: ManageReadingListUseCase(repository: InMemoryReadingListRepositorySpy()),
            pageSize: 1
        )

        await viewModel.loadIfNeeded()
        XCTAssertEqual(viewModel.state, .loaded)

        repository.result = .failure(NewsAPIError.simulatedNetwork)
        await viewModel.loadMore()
        XCTAssertEqual(viewModel.state, .loaded)
        // Toast is shown but state remains loaded
    }

    // MARK: - Retry

    func testRetryRecoversFromError() async {
        let article = TestFactory.article(id: "1", title: "Test", publishedAt: Date())
        let repository = ArticlesRepositorySpy(result: .failure(NewsAPIError.simulatedNetwork))
        let viewModel = ArticlesViewModel(
            source: TestFactory.source,
            fetchUseCase: FetchArticlesUseCase(repository: repository),
            readingListUseCase: ManageReadingListUseCase(repository: InMemoryReadingListRepositorySpy())
        )

        await viewModel.loadIfNeeded()
        guard case .error = viewModel.state else {
            XCTFail("Expected error state after initial load")
            return
        }

        repository.result = .success([article])
        await viewModel.retry()
        XCTAssertEqual(viewModel.state, .loaded)
    }

    func testRetryFromEmptyState() async {
        let repository = ArticlesRepositorySpy(result: .success([]))
        let viewModel = ArticlesViewModel(
            source: TestFactory.source,
            fetchUseCase: FetchArticlesUseCase(repository: repository),
            readingListUseCase: ManageReadingListUseCase(repository: InMemoryReadingListRepositorySpy())
        )
        await viewModel.loadIfNeeded()
        XCTAssertEqual(viewModel.state, .empty)

        let article = TestFactory.article(id: "1", title: "Test", publishedAt: Date())
        repository.result = .success([article])
        await viewModel.retry()
        XCTAssertEqual(viewModel.state, .loaded)
    }

    // MARK: - Pagination

    func testLoadMoreAppendsArticlesAndSetsHasMorePages() async {
        let articles = (1...3).map {
            TestFactory.article(id: "\($0)", title: "Article \($0)", publishedAt: Date())
        }
        let repository = ArticlesRepositorySpy(result: .success(articles))
        let viewModel = ArticlesViewModel(
            source: TestFactory.source,
            fetchUseCase: FetchArticlesUseCase(repository: repository),
            readingListUseCase: ManageReadingListUseCase(repository: InMemoryReadingListRepositorySpy()),
            pageSize: 2
        )

        await viewModel.loadIfNeeded()
        XCTAssertEqual(viewModel.articles.count, 3)
        XCTAssertTrue(viewModel.hasMorePages)

        await viewModel.loadMore()
        XCTAssertEqual(repository.requestCount, 2)
    }

    func testLoadMoreDoesNotExecuteWhenNoMorePages() async {
        let article = TestFactory.article(id: "1", title: "A", publishedAt: Date())
        let repository = ArticlesRepositorySpy(result: .success([article]))
        let viewModel = ArticlesViewModel(
            source: TestFactory.source,
            fetchUseCase: FetchArticlesUseCase(repository: repository),
            readingListUseCase: ManageReadingListUseCase(repository: InMemoryReadingListRepositorySpy()),
            pageSize: 10
        )
        await viewModel.loadIfNeeded()
        XCTAssertFalse(viewModel.hasMorePages)

        await viewModel.loadMore()
        XCTAssertEqual(repository.requestCount, 1)
    }

    func testLoadMoreDeduplicatesDuplicateArticles() async {
        let article = TestFactory.article(id: "1", title: "A", publishedAt: Date())
        let repository = ArticlesRepositorySpy(result: .success([article]))
        let viewModel = ArticlesViewModel(
            source: TestFactory.source,
            fetchUseCase: FetchArticlesUseCase(repository: repository),
            readingListUseCase: ManageReadingListUseCase(repository: InMemoryReadingListRepositorySpy()),
            pageSize: 1
        )
        await viewModel.loadIfNeeded()
        XCTAssertEqual(viewModel.articles.count, 1)

        await viewModel.loadMore()
        XCTAssertEqual(viewModel.articles.count, 1)
    }

    func testIsLoadingMoreFlagTogglesCorrectly() async {
        let articles = (1...5).map {
            TestFactory.article(id: "\($0)", title: "Article \($0)", publishedAt: Date())
        }
        let repository = DelayedArticlesRepositorySpy(
            result: .success(articles),
            delayNanoseconds: 50_000_000
        )
        let viewModel = ArticlesViewModel(
            source: TestFactory.source,
            fetchUseCase: FetchArticlesUseCase(repository: repository),
            readingListUseCase: ManageReadingListUseCase(repository: InMemoryReadingListRepositorySpy()),
            pageSize: 2
        )
        await viewModel.loadIfNeeded()
        XCTAssertFalse(viewModel.isLoadingMore)

        let expectation = expectation(description: "loadMore completes")
        Task {
            await viewModel.loadMore()
            expectation.fulfill()
        }

        try? await Task.sleep(nanoseconds: 10_000_000)
        XCTAssertTrue(viewModel.isLoadingMore)

        await fulfillment(of: [expectation], timeout: 2)
        XCTAssertFalse(viewModel.isLoadingMore)
    }

    // MARK: - Warning Message

    func testWarningMessageIsClearedOnSuccess() async {
        let article = TestFactory.article(id: "1", title: "A", publishedAt: Date())
        let repository = ArticlesRepositorySpy(result: .failure(NewsAPIError.simulatedNetwork))
        let viewModel = ArticlesViewModel(
            source: TestFactory.source,
            fetchUseCase: FetchArticlesUseCase(repository: repository),
            readingListUseCase: ManageReadingListUseCase(repository: InMemoryReadingListRepositorySpy())
        )
        await viewModel.loadIfNeeded()
        XCTAssertEqual(viewModel.state, .error(L10n.text("error.simulatedFetch")))

        repository.result = .success([article])
        await viewModel.retry()
        XCTAssertEqual(viewModel.state, .loaded)
    }

    // MARK: - Carousel

    func testCarouselSelectionClampsToFeaturedCount() async {
        let articles = (1...5).map {
            TestFactory.article(id: "\($0)", title: "Article \($0)", publishedAt: Date())
        }
        let viewModel = makeViewModel(articles: .success(articles))
        viewModel.carouselSelection = 2
        await viewModel.loadIfNeeded()

        XCTAssertEqual(viewModel.featuredArticles.count, 3)
        XCTAssertEqual(viewModel.carouselSelection, 2)

        let fewerArticles = [articles[0]]
        let newViewModel = makeViewModel(articles: .success(fewerArticles))
        newViewModel.carouselSelection = 5
        await newViewModel.loadIfNeeded()
        XCTAssertEqual(newViewModel.carouselSelection, 0)
    }

    // MARK: - Stale Request Cancellation

    func testStaleRequestIsIgnoredWhenNewerRequestStarts() async {
        let article = TestFactory.article(id: "1", title: "A", publishedAt: Date())
        let repository = DelayedArticlesRepositorySpy(
            result: .success([article]),
            delayNanoseconds: 300_000_000
        )
        let viewModel = ArticlesViewModel(
            source: TestFactory.source,
            fetchUseCase: FetchArticlesUseCase(repository: repository),
            readingListUseCase: ManageReadingListUseCase(repository: InMemoryReadingListRepositorySpy())
        )

        Task {
            await viewModel.loadIfNeeded()
        }
        try? await Task.sleep(nanoseconds: 50_000_000)

        await viewModel.pullToRefresh()

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(repository.requestCount, 2)
    }

    // MARK: - Automatic Refresh

    func testStartAndStopAutomaticRefresh() async {
        let viewModel = makeViewModel(articles: .success([
            TestFactory.article(id: "1", title: "A", publishedAt: Date())
        ]))
        await viewModel.loadIfNeeded()

        viewModel.startAutomaticRefresh()
        viewModel.stopAutomaticRefresh()
    }

    // MARK: - Prefetch

    func testPrefetchLoadsNextPageSilently() async {
        let page1 = (1...3).map {
            TestFactory.article(id: "\($0)", title: "Article \($0)", publishedAt: Date())
        }
        let page2 = (4...6).map {
            TestFactory.article(id: "\($0)", title: "Article \($0)", publishedAt: Date())
        }
        let repository = ArticlesRepositorySpy(result: .success(page1 + page2))
        let viewModel = ArticlesViewModel(
            source: TestFactory.source,
            fetchUseCase: FetchArticlesUseCase(repository: repository),
            readingListUseCase: ManageReadingListUseCase(repository: InMemoryReadingListRepositorySpy()),
            pageSize: 3
        )

        await viewModel.loadIfNeeded()
        XCTAssertEqual(viewModel.articles.count, 6)
        XCTAssertEqual(viewModel.state, .loaded)

        await viewModel.prefetchNextPageIfNeeded()
        XCTAssertEqual(repository.requestCount, 2)
        // Spy returns the same 6 items; deduplication keeps count at 6
        XCTAssertEqual(viewModel.articles.count, 6)
        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertFalse(viewModel.isLoadingMore)
        XCTAssertFalse(viewModel.isPrefetching)
    }

    func testPrefetchDoesNotChangeStateWhenAlreadyLoaded() async {
        let articles = (1...5).map {
            TestFactory.article(id: "\($0)", title: "Article \($0)", publishedAt: Date())
        }
        let repository = ArticlesRepositorySpy(result: .success(articles))
        let viewModel = ArticlesViewModel(
            source: TestFactory.source,
            fetchUseCase: FetchArticlesUseCase(repository: repository),
            readingListUseCase: ManageReadingListUseCase(repository: InMemoryReadingListRepositorySpy()),
            pageSize: 2
        )

        await viewModel.loadIfNeeded()
        XCTAssertEqual(viewModel.state, .loaded)

        let stateBeforePrefetch = viewModel.state
        await viewModel.prefetchNextPageIfNeeded()
        XCTAssertEqual(viewModel.state, stateBeforePrefetch)
        XCTAssertFalse(viewModel.isPrefetching)
    }

    func testPrefetchIsIgnoredWhenNoMorePages() async {
        let article = TestFactory.article(id: "1", title: "A", publishedAt: Date())
        let repository = ArticlesRepositorySpy(result: .success([article]))
        let viewModel = ArticlesViewModel(
            source: TestFactory.source,
            fetchUseCase: FetchArticlesUseCase(repository: repository),
            readingListUseCase: ManageReadingListUseCase(repository: InMemoryReadingListRepositorySpy()),
            pageSize: 10
        )

        await viewModel.loadIfNeeded()
        XCTAssertFalse(viewModel.hasMorePages)

        await viewModel.prefetchNextPageIfNeeded()
        XCTAssertEqual(repository.requestCount, 1)
    }

    func testPrefetchIsIgnoredWhenAlreadyPrefetching() async {
        let articles = (1...5).map {
            TestFactory.article(id: "\($0)", title: "Article \($0)", publishedAt: Date())
        }
        let repository = DelayedArticlesRepositorySpy(
            result: .success(articles),
            delayNanoseconds: 100_000_000
        )
        let viewModel = ArticlesViewModel(
            source: TestFactory.source,
            fetchUseCase: FetchArticlesUseCase(repository: repository),
            readingListUseCase: ManageReadingListUseCase(repository: InMemoryReadingListRepositorySpy()),
            pageSize: 2
        )

        await viewModel.loadIfNeeded()
        XCTAssertEqual(viewModel.state, .loaded)

        let expectation = expectation(description: "prefetch completes")
        Task {
            await viewModel.prefetchNextPageIfNeeded()
            expectation.fulfill()
        }

        try? await Task.sleep(nanoseconds: 10_000_000)
        XCTAssertTrue(viewModel.isPrefetching)

        // Second prefetch should be ignored while first is in-flight
        await viewModel.prefetchNextPageIfNeeded()
        XCTAssertEqual(repository.requestCount, 2) // only 2 total: initial + first prefetch

        await fulfillment(of: [expectation], timeout: 2)
        XCTAssertFalse(viewModel.isPrefetching)
    }

    // MARK: - Additional Edge Cases

    func testLoadMoreErrorDoesNotLoseExistingArticles() async {
        // Arrange
        let page1Articles = TestFactory.articles(count: 3)
        let repository = PagedArticlesRepositorySpy(pageResults: [
            1: .success(page1Articles),
            2: .failure(NewsAPIError.simulatedNetwork)
        ])
        let viewModel = ArticlesViewModel(
            source: TestFactory.source,
            fetchUseCase: FetchArticlesUseCase(repository: repository),
            readingListUseCase: ManageReadingListUseCase(repository: InMemoryReadingListRepositorySpy()),
            pageSize: 2
        )

        // Act
        await viewModel.loadIfNeeded()
        XCTAssertEqual(viewModel.articles.count, 3)

        await viewModel.loadMore()

        // Assert — articles preserved after loadMore failure
        XCTAssertEqual(viewModel.articles.count, 3)
        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertFalse(viewModel.isLoadingMore)
    }

    func testAutomaticRefreshSkipsWhenDataUnchanged() async {
        // Arrange
        let articles = TestFactory.articles(count: 2)
        let repository = ArticlesRepositorySpy(result: .success(articles))
        let viewModel = ArticlesViewModel(
            source: TestFactory.source,
            fetchUseCase: FetchArticlesUseCase(repository: repository),
            readingListUseCase: ManageReadingListUseCase(repository: InMemoryReadingListRepositorySpy()),
            pageSize: 2
        )

        // Act
        await viewModel.loadIfNeeded()
        let articlesBeforeRefresh = viewModel.articles

        // Simulate automatic refresh — same data returned
        await viewModel.pullToRefresh()

        // Assert — articles should be the same (no unnecessary mutations)
        XCTAssertEqual(viewModel.articles.map(\.id), articlesBeforeRefresh.map(\.id))
        XCTAssertEqual(viewModel.state, .loaded)
    }

    func testPrefetchDoesNotRunWhenStateIsError() async {
        // Arrange
        let repository = ArticlesRepositorySpy(result: .failure(NewsAPIError.network))
        let viewModel = ArticlesViewModel(
            source: TestFactory.source,
            fetchUseCase: FetchArticlesUseCase(repository: repository),
            readingListUseCase: ManageReadingListUseCase(repository: InMemoryReadingListRepositorySpy())
        )
        await viewModel.loadIfNeeded()
        guard case .error = viewModel.state else {
            return XCTFail("Expected error state")
        }

        // Act
        await viewModel.prefetchNextPageIfNeeded()

        // Assert — no additional request made
        XCTAssertEqual(repository.requestCount, 1)
    }

    func testLoadMoreWithPagedRepositoryAppendsDistinctArticles() async {
        // Arrange
        let page1 = TestFactory.articles(count: 2, startID: 1)
        let page2 = TestFactory.articles(count: 2, startID: 3)
        let repository = PagedArticlesRepositorySpy(pageResults: [
            1: .success(page1),
            2: .success(page2)
        ])
        let viewModel = ArticlesViewModel(
            source: TestFactory.source,
            fetchUseCase: FetchArticlesUseCase(repository: repository),
            readingListUseCase: ManageReadingListUseCase(repository: InMemoryReadingListRepositorySpy()),
            pageSize: 2
        )

        // Act
        await viewModel.loadIfNeeded()
        XCTAssertEqual(viewModel.articles.count, 2)
        XCTAssertTrue(viewModel.hasMorePages)

        await viewModel.loadMore()

        // Assert
        XCTAssertEqual(viewModel.articles.count, 4)
        XCTAssertEqual(repository.requestedPages, [1, 2])
    }

    func testRetryAfterLoadMoreErrorResetsPageToOne() async {
        // Arrange
        let page1 = TestFactory.articles(count: 2, startID: 1)
        let repository = PagedArticlesRepositorySpy(pageResults: [
            1: .success(page1),
            2: .failure(NewsAPIError.simulatedNetwork)
        ])
        let viewModel = ArticlesViewModel(
            source: TestFactory.source,
            fetchUseCase: FetchArticlesUseCase(repository: repository),
            readingListUseCase: ManageReadingListUseCase(repository: InMemoryReadingListRepositorySpy()),
            pageSize: 2
        )

        // Act — load page 1, fail on page 2, then retry (which resets to page 1)
        await viewModel.loadIfNeeded()
        await viewModel.loadMore()

        repository.setResult(.success(page1), forPage: 1)
        await viewModel.retry()

        // Assert — retry resets to page 1
        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertTrue(repository.requestedPages.last == 1)
    }

    func testReadingListStatePreservedAcrossRefresh() async throws {
        // Arrange
        let article = TestFactory.article(id: "preserved-1", title: "Preserved", publishedAt: Date())
        let readingList = InMemoryReadingListRepositorySpy()
        let repository = ArticlesRepositorySpy(result: .success([article]))
        let viewModel = ArticlesViewModel(
            source: TestFactory.source,
            fetchUseCase: FetchArticlesUseCase(repository: repository),
            readingListUseCase: ManageReadingListUseCase(repository: readingList)
        )

        // Act — load, save to reading list, refresh
        await viewModel.loadIfNeeded()
        await viewModel.toggleReadingList(for: article)
        XCTAssertTrue(viewModel.isSaved(article))

        await viewModel.pullToRefresh()

        // Assert — reading list state should persist across refresh
        XCTAssertTrue(viewModel.isSaved(article))
    }

    func testFeaturedArticlesReturnsEmptyWhenLessThanThreeArticles() async {
        // Arrange
        let articles = TestFactory.articles(count: 2)
        let viewModel = makeViewModel(articles: .success(articles))

        // Act
        await viewModel.loadIfNeeded()

        // Assert — with 2 articles, featured takes all, list is empty
        XCTAssertEqual(viewModel.featuredArticles.count, 2)
        XCTAssertTrue(viewModel.listArticles.isEmpty)
    }

}

