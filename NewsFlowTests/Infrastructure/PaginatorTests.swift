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
}

// MARK: - Array Safe Access Helper

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
