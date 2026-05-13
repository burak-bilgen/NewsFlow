import XCTest
@testable import NewsApto

final class ReadArticlesTrackerTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        await ReadArticlesTracker.shared.clearAll()
    }

    func testInitiallyEmpty() async {
        let isRead = await ReadArticlesTracker.shared.isRead("article-1")
        XCTAssertFalse(isRead)
    }

    func testMarkAsRead() async {
        await ReadArticlesTracker.shared.markAsRead("article-1")
        let isRead = await ReadArticlesTracker.shared.isRead("article-1")
        XCTAssertTrue(isRead)
    }

    func testMarkMultipleAsRead() async {
        await ReadArticlesTracker.shared.markAsRead("a")
        await ReadArticlesTracker.shared.markAsRead("b")
        await ReadArticlesTracker.shared.markAsRead("c")

        let aIsRead = await ReadArticlesTracker.shared.isRead("a")
        let bIsRead = await ReadArticlesTracker.shared.isRead("b")
        let cIsRead = await ReadArticlesTracker.shared.isRead("c")
        let dIsRead = await ReadArticlesTracker.shared.isRead("d")
        XCTAssertTrue(aIsRead)
        XCTAssertTrue(bIsRead)
        XCTAssertTrue(cIsRead)
        XCTAssertFalse(dIsRead)
    }

    func testMarkAsUnread() async {
        await ReadArticlesTracker.shared.markAsRead("article-1")
        await ReadArticlesTracker.shared.markAsUnread("article-1")
        let isRead = await ReadArticlesTracker.shared.isRead("article-1")
        XCTAssertFalse(isRead)
    }

    func testClearAll() async {
        await ReadArticlesTracker.shared.markAsRead("a")
        await ReadArticlesTracker.shared.markAsRead("b")
        await ReadArticlesTracker.shared.clearAll()

        let aIsRead = await ReadArticlesTracker.shared.isRead("a")
        let bIsRead = await ReadArticlesTracker.shared.isRead("b")
        XCTAssertFalse(aIsRead)
        XCTAssertFalse(bIsRead)
    }

    func testMarkAsReadIsIdempotent() async {
        await ReadArticlesTracker.shared.markAsRead("article-1")
        await ReadArticlesTracker.shared.markAsRead("article-1")
        await ReadArticlesTracker.shared.markAsRead("article-1")

        let isRead = await ReadArticlesTracker.shared.isRead("article-1")
        XCTAssertTrue(isRead)
    }

    func testMarkAsReadNonisolated() async {
        ReadArticlesTracker.shared.markAsReadNonisolated("article-1")
        try? await Task.sleep(nanoseconds: 50_000_000)
        let isRead = await ReadArticlesTracker.shared.isRead("article-1")
        XCTAssertTrue(isRead)
    }
}
