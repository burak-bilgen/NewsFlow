import XCTest
@testable import NewsApto

final class DeepLinkTests: XCTestCase {
    func testArticleDeepLink() {
        let url = URL(string: "newsflow://article/abc-123")!
        let link = DeepLink(url: url)
        XCTAssertEqual(link, .article(id: "abc-123"))
    }

    func testSourceDeepLink() {
        let url = URL(string: "newsflow://source/bbc-news")!
        let link = DeepLink(url: url)
        XCTAssertEqual(link, .source(id: "bbc-news"))
    }

    func testSearchDeepLink() {
        let url = URL(string: "newsflow://search?q=bitcoin")!
        let link = DeepLink(url: url)
        XCTAssertEqual(link, .search(query: "bitcoin"))
    }

    func testSearchDeepLinkWithEncodedQuery() {
        let url = URL(string: "newsflow://search?q=breaking%20news")!
        let link = DeepLink(url: url)
        XCTAssertEqual(link, .search(query: "breaking news"))
    }

    func testSearchDeepLinkMissingQuery() {
        let url = URL(string: "newsflow://search")!
        let link = DeepLink(url: url)
        XCTAssertNil(link)
    }

    func testReadingListDeepLink() {
        let url = URL(string: "newsflow://reading-list")!
        let link = DeepLink(url: url)
        XCTAssertEqual(link, .readingList)
    }

    func testUnknownSchemeReturnsNil() {
        let url = URL(string: "https://example.com/article")!
        let link = DeepLink(url: url)
        XCTAssertNil(link)
    }

    func testUnknownHostReturnsNil() {
        let url = URL(string: "newsflow://unknown/path")!
        let link = DeepLink(url: url)
        XCTAssertNil(link)
    }

    func testInvalidURLReturnsNil() {
        let link = DeepLink(url: URL(string: "newsflow://")!)
        XCTAssertNil(link)
    }
}

final class DeepLinkHandlerTests: XCTestCase {
    func testHandleArticleDeepLink() {
        let url = URL(string: "newsflow://article/test-123")!
        let result = DeepLinkHandler.shared.handle(url)
        XCTAssertTrue(result)
    }

    func testHandleInvalidDeepLink() {
        let url = URL(string: "https://example.com")!
        let result = DeepLinkHandler.shared.handle(url)
        XCTAssertFalse(result)
    }
}
