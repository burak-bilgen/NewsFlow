import XCTest
@testable import NewsApto

final class ArticleTests: XCTestCase {
    func testArticleSortingNewestFirst() {
        let old = TestFactory.article(id: "old", title: "Old", publishedAt: Date(timeIntervalSince1970: 10))
        let new = TestFactory.article(id: "new", title: "New", publishedAt: Date(timeIntervalSince1970: 30))
        let undated = TestFactory.article(id: "undated", title: "Undated", publishedAt: nil)

        let sorted = ArticleSorter().newestFirst([old, undated, new])

        XCTAssertEqual(sorted.map(\.id), ["new", "old", "undated"])
    }

    func testDistinctContentSnippetHidesDuplicateDescription() {
        let article = Article(
            id: "1",
            sourceID: "guardian",
            title: "Markets Rally",
            description: "Global markets rallied today.",
            contentSnippet: "  Global markets rallied today.  "
        )

        XCTAssertNil(article.distinctContentSnippet)
    }

    func testDistinctContentSnippetKeepsAdditionalContext() {
        let article = Article(
            id: "1",
            sourceID: "guardian",
            title: "Markets Rally",
            description: "Global markets rallied today.",
            contentSnippet: "Analysts said the move followed stronger earnings guidance."
        )

        XCTAssertEqual(
            article.distinctContentSnippet,
            "Analysts said the move followed stronger earnings guidance."
        )
    }
}
