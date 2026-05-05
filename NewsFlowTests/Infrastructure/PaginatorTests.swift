import XCTest
@testable import NewsFlow

// MARK: - Paginator Tests

@MainActor
final class PaginatorTests: XCTestCase {
    private func makePaginator(items: [[Article]] = [[]]) -> Paginator<Article> {
        var pageIndex = 0
        return Paginator<Article>(pageSize: 2) { page, pageSize in
            let currentItems = items[safe: pageIndex] ?? []
            let hasMore = pageIndex < items.count - 1
            pageIndex += 1
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
        let paginator = makePaginator(items: [[article, article]])

        let state = await paginator.loadFirst()

        guard case .loaded(let items, let hasMore) = state else {
            return XCTFail("Expected loaded state")
        }
        XCTAssertEqual(items.count, 2)
        XCTAssertFalse(hasMore)
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

        guard case .loaded(let items, _) = state else {
            return XCTFail("Expected loaded state")
        }
        XCTAssertEqual(items.count, 3)
    }

    func testDeduplicationRemovesDuplicateIDs() async {
        let article = TestFactory.article(id: "1", title: "A", publishedAt: Date())
        let paginator = makePaginator(items: [[article], [article]])

        _ = await paginator.loadFirst()
        let state = await paginator.loadNext()

        guard case .loaded(let items, _) = state else {
            return XCTFail("Expected loaded state")
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

        guard case .loaded(let items, _) = state else {
            return XCTFail("Expected loaded state")
        }
        XCTAssertEqual(items.count, 1) // resets to page 1
    }

    func testAllLoadedStateWhenNoMorePages() async {
        let article = TestFactory.article(id: "1", title: "A", publishedAt: Date())
        let paginator = makePaginator(items: [[article]])

        let state = await paginator.loadFirst()

        guard case .allLoaded = state else {
            return XCTFail("Expected allLoaded state")
        }
        XCTAssertFalse(paginator.hasMore)
    }

    func testPrefetchSilentlyLoadsMore() async {
        let page1 = [TestFactory.article(id: "1", title: "A", publishedAt: Date())]
        let page2 = [TestFactory.article(id: "2", title: "B", publishedAt: Date())]
        let paginator = makePaginator(items: [page1, page2])

        _ = await paginator.loadFirst()
        let state = await paginator.prefetch()

        guard case .loaded(let items, _) = state else {
            return XCTFail("Expected loaded state")
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
