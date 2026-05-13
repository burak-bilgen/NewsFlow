import XCTest
@testable import NewsApto

@MainActor
final class FeedViewModelTests: XCTestCase {
    private func makeSUT(
        feedResult: Result<[Article], Error> = .success([]),
        readingListIDs: Set<String> = [],
        pageSize: Int = 20
    ) -> (FeedViewModel, ArticlesRepositorySpy, InMemoryReadingListRepositorySpy) {
        let feedRepo = ArticlesRepositorySpy(result: feedResult)
        let readingListRepo = InMemoryReadingListRepositorySpy()
        let readingListUseCase = ManageReadingListUseCase(repository: readingListRepo)
        Task {
            for id in readingListIDs {
                try? await readingListRepo.add(TestFactory.article(id: id, title: id, publishedAt: Date()))
            }
        }
        let guardianStub = StubGuardianClient(result: .success([]))
        let nytStub = StubNYTClient(result: .success(NYTSearchResult(articles: [], hasMore: false)))
        let aggregator = NewsAggregatorService(
            newsAPIRepository: feedRepo,
            guardianClient: guardianStub,
            nytClient: nytStub
        )
        let vm = FeedViewModel(aggregator: aggregator, readingListUseCase: readingListUseCase, pageSize: pageSize)
        return (vm, feedRepo, readingListRepo)
    }

    func testInitialStateIsIdle() {
        let (vm, _, _) = makeSUT()
        XCTAssertEqual(vm.state, .idle)
        XCTAssertTrue(vm.articles.isEmpty)
        XCTAssertTrue(vm.savedArticleIDs.isEmpty)
        XCTAssertFalse(vm.isRefreshing)
        XCTAssertTrue(vm.hasMorePages)
    }

    func testLoadIfNeededTransitionsToReady() async {
        let articles = TestFactory.articles(count: 5)
        let (vm, _, _) = makeSUT(feedResult: .success(articles))
        await vm.loadIfNeeded()
        XCTAssertEqual(vm.state, .ready)
        XCTAssertEqual(vm.articles.count, 5)
    }

    func testLoadIfNeededDoesNotFetchIfAlreadyLoaded() async {
        let articles = TestFactory.articles(count: 5)
        let (vm, repo, _) = makeSUT(feedResult: .success(articles))
        await vm.loadIfNeeded()
        await vm.loadIfNeeded()
        XCTAssertEqual(vm.state, .ready)
        XCTAssertEqual(repo.requestCount, 1)
    }

    func testLoadIfNeededSetsEmptyState() async {
        let (vm, _, _) = makeSUT(feedResult: .success([]))
        await vm.loadIfNeeded()
        XCTAssertEqual(vm.state, .empty)
    }

    func testPullToRefreshResetsAndFetches() async {
        let initial = TestFactory.articles(count: 3, startID: 1)
        let refreshed = TestFactory.articles(count: 5, startID: 10)
        let (vm, repo, _) = makeSUT(feedResult: .success(initial))
        await vm.loadIfNeeded()
        XCTAssertEqual(vm.articles.count, 3)
        repo.result = .success(refreshed)
        await vm.pullToRefresh()
        XCTAssertEqual(vm.articles.count, 5)
        XCTAssertFalse(vm.isRefreshing)
    }

    func testIsSavedChecksReadArticles() async {
        let article = TestFactory.article(id: "1", title: "Test", publishedAt: Date())
        let (vm, _, readingListRepo) = makeSUT(feedResult: .success([article]))
        try? await readingListRepo.add(article)
        await vm.loadIfNeeded()
        XCTAssertTrue(vm.isSaved(article))
    }

    func testToggleReadingListAddsAndRemoves() async {
        let article = TestFactory.article(id: "1", title: "Test", publishedAt: Date())
        let (vm, _, _) = makeSUT(feedResult: .success([article]))
        await vm.loadIfNeeded()
        await vm.toggleReadingList(for: article)
        XCTAssertTrue(vm.isSaved(article))
        await vm.toggleReadingList(for: article)
        XCTAssertFalse(vm.isSaved(article))
    }
}
