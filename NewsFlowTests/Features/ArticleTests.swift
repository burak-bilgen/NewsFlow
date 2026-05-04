import XCTest
@testable import NewsFlow

final class ArticleTests: XCTestCase {
    func testArticleSortingNewestFirst() {
        let old = TestFactory.article(id: "old", title: "Old", publishedAt: Date(timeIntervalSince1970: 10))
        let new = TestFactory.article(id: "new", title: "New", publishedAt: Date(timeIntervalSince1970: 30))
        let undated = TestFactory.article(id: "undated", title: "Undated", publishedAt: nil)

        let sorted = ArticleSorter.newestFirst([old, undated, new])

        XCTAssertEqual(sorted.map(\.id), ["new", "old", "undated"])
    }
}
