import XCTest
@testable import NewsFlow

// MARK: - Paginator Tests

@MainActor
final class PaginatorTests: XCTestCase {
    private func makePaginator(items: [[Article]] = [[]]) -> Paginator<Article> {
        return Paginator<Article>(pageSize: 2) { page, pageSize in
            let index = page - 1
            let currentItems = items[safe: index] ?? []
            let hasMore = index < items.count - 1
            return PaginatedResult(
                items: currentItems,
                currentPage: page,
                hasMorePages: hasMore
            )
        }
    }

    func testInitialStateIsIdle() {
        let paginator = makePaginator()
        XCTAssertEqual(paginator.state, .idle)
        XCTAssertTrue(paginator.isEmpty)
    }

    func testLoadFirstReturnsLoadedWithItems() async {
        let article = TestFactory.article(id: "1", title: "A", publishedAt: Date())
        let paginator = makePaginator(items: [[article, article], [article]])

        let state = await paginator.loadFirst()

        // With 2+ pages, first load returns .loaded
        guard case .loaded(let items, let hasMore) = state else {
            return XCTFail("Expected loaded state, got \(state)")
        }
        XCTAssertEqual(items.count, 2)
        XCTAssertTrue(hasMore)
    }

    func testLoadFirstReturnsAllLoadedWhenSinglePage() async {
        let article = TestFactory.article(id: "1", title: "A", publishedAt: Date())
        let paginator = makePaginator(items: [[article, article]])

        let state = await paginator.loadFirst()

        // Single page returns .allLoaded
        guard case .allLoaded(let items) = state else {
            return XCTFail("Expected allLoaded state, got \(state)")
        }
        XCTAssertEqual(items.count, 2)
        XCTAssertFalse(paginator.hasMore)
    }

    func testLoadFirstReturnsEmpty() async {
        let paginator = makePaginator(items: [[]])

        let state = await paginator.loadFirst()

        XCTAssertEqual(state, .empty)
    }

    func testLoadNextAppendsItems() async {
        let page1 = [
            TestFactory.article(id: "1", title: "A", publishedAt: Date()),
            TestFactory.article(id: "2", title: "B", publishedAt: Date())
        ]
        let page2 = [
            TestFactory.article(id: "3", title: "C", publishedAt: Date())
        ]
        let paginator = makePaginator(items: [page1, page2])

        _ = await paginator.loadFirst()
        let state = await paginator.loadNext()

        // After loading last page, state is .allLoaded
        guard case .allLoaded(let items) = state else {
            return XCTFail("Expected allLoaded state, got \(state)")
        }
        XCTAssertEqual(items.count, 3)
    }

    func testDeduplicationRemovesDuplicateIDs() async {
        let article = TestFactory.article(id: "1", title: "A", publishedAt: Date())
        let paginator = makePaginator(items: [[article], [article]])

        _ = await paginator.loadFirst()
        let state = await paginator.loadNext()

        guard case .allLoaded(let items) = state else {
            return XCTFail("Expected allLoaded state, got \(state)")
        }
        XCTAssertEqual(items.count, 1)
    }

    func testRefreshResetsAndReloads() async {
        let page1 = [TestFactory.article(id: "1", title: "A", publishedAt: Date())]
        let page2 = [TestFactory.article(id: "2", title: "B", publishedAt: Date())]
        let paginator = makePaginator(items: [page1, page2])

        _ = await paginator.loadFirst()
        _ = await paginator.loadNext()
        let state = await paginator.refresh()

        // Refresh resets to page 1
        guard case .loaded(let items, _) = state else {
            return XCTFail("Expected loaded state, got \(state)")
        }
        XCTAssertEqual(items.count, 1)
    }

    func testAllLoadedStateWhenNoMorePages() async {
        let article = TestFactory.article(id: "1", title: "A", publishedAt: Date())
        let paginator = makePaginator(items: [[article]])

        let state = await paginator.loadFirst()

        guard case .allLoaded = state else {
            return XCTFail("Expected allLoaded state, got \(state)")
        }
        XCTAssertFalse(paginator.hasMore)
    }

    func testPrefetchSilentlyLoadsMore() async {
        let page1 = [TestFactory.article(id: "1", title: "A", publishedAt: Date())]
        let page2 = [TestFactory.article(id: "2", title: "B", publishedAt: Date())]
        let paginator = makePaginator(items: [page1, page2])

        _ = await paginator.loadFirst()
        let state = await paginator.prefetch()

        // After prefetching last page, state is .allLoaded
        guard case .allLoaded(let items) = state else {
            return XCTFail("Expected allLoaded state, got \(state)")
        }
        XCTAssertEqual(items.count, 2)
    }

    // MARK: - Error Paths

    func testLoadFirstErrorSetsErrorState() async {
        // Arrange
        let paginator = Paginator<Article>(pageSize: 2) { _, _ in
            throw NewsAPIError.network
        }

        // Act
        let state = await paginator.loadFirst()

        // Assert
        guard case .error(let message, let existingItems) = state else {
            return XCTFail("Expected error state, got \(state)")
        }
        XCTAssertFalse(message.isEmpty)
        XCTAssertNil(existingItems)
        XCTAssertTrue(paginator.isEmpty)
    }

    func testLoadNextErrorRevertsPageAndKeepsExistingItems() async {
        // Arrange
        let article = TestFactory.article(id: "1", title: "A", publishedAt: Date())
        var shouldFail = false
        let paginator = Paginator<Article>(pageSize: 1) { page, _ in
            if shouldFail {
                throw NewsAPIError.simulatedNetwork
            }
            return PaginatedResult(items: [article], currentPage: page, hasMorePages: true)
        }

        // Act — load first page successfully, then fail on page 2
        _ = await paginator.loadFirst()
        shouldFail = true
        let state = await paginator.loadNext()

        // Assert — items preserved, still shows loaded (with existing items)
        guard case .loaded(let items, _) = state else {
            return XCTFail("Expected loaded state with existing items, got \(state)")
        }
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.id, "1")
    }

    func testRetryAfterErrorLoadsCorrectPage() async {
        // Arrange
        var callCount = 0
        let article = TestFactory.article(id: "1", title: "A", publishedAt: Date())
        let paginator = Paginator<Article>(pageSize: 2) { _, _ in
            callCount += 1
            if callCount == 1 {
                throw NewsAPIError.network
            }
            return PaginatedResult(items: [article], currentPage: 1, hasMorePages: false)
        }

        // Act — first call fails, retry succeeds
        _ = await paginator.loadFirst()
        guard case .error = paginator.state else {
            return XCTFail("Expected error state after first load")
        }

        let state = await paginator.retry()

        // Assert
        guard case .allLoaded(let items) = state else {
            return XCTFail("Expected allLoaded state after retry, got \(state)")
        }
        XCTAssertEqual(items.count, 1)
    }

    func testConcurrentLoadsAreIgnored() async {
        // Arrange
        var callCount = 0
        let article = TestFactory.article(id: "1", title: "A", publishedAt: Date())
        let paginator = Paginator<Article>(pageSize: 2) { _, _ in
            callCount += 1
            try await Task.sleep(nanoseconds: 100_000_000)
            return PaginatedResult(items: [article], currentPage: 1, hasMorePages: false)
        }

        // Act — start two loads concurrently
        async let first = paginator.loadFirst()
        try? await Task.sleep(nanoseconds: 10_000_000)
        async let second = paginator.loadFirst()

        _ = await (first, second)

        // Assert — only one load actually executed
        XCTAssertEqual(callCount, 1)
    }

    func testRetryFromErrorWithExistingItemsLoadsCurrentPage() async {
        // Arrange
        let page1 = [TestFactory.article(id: "1", title: "A", publishedAt: Date())]
        var callCount = 0
        let paginator = Paginator<Article>(pageSize: 1) { page, _ in
            callCount += 1
            if callCount == 2 {
                throw NewsAPIError.network
            }
            return PaginatedResult(items: page1, currentPage: page, hasMorePages: true)
        }

        // Act — load page 1, fail on page 2, retry
        _ = await paginator.loadFirst()
        _ = await paginator.loadNext() // fails
        let retryState = await paginator.retry()

        // Assert — retry succeeds and items are repopulated
        XCTAssertFalse(paginator.isEmpty)
        switch retryState {
        case .loaded, .allLoaded:
            break // Success
        default:
            XCTFail("Expected loaded or allLoaded state after retry, got \(retryState)")
        }
    }

    func testLoadFirstErrorWithSimulatedNetworkShowsCorrectMessage() async {
        // Arrange
        let paginator = Paginator<Article>(pageSize: 2) { _, _ in
            throw NewsAPIError.simulatedNetwork
        }

        // Act
        let state = await paginator.loadFirst()

        // Assert
        guard case .error(let message, _) = state else {
            return XCTFail("Expected error state, got \(state)")
        }
        XCTAssertEqual(message, NewsAPIError.simulatedNetwork.userMessage)
    }
}

// MARK: - Array Safe Access Helper

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

