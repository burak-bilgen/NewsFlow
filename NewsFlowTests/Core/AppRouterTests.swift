import XCTest
@testable import NewsFlow

@MainActor
final class AppRouterTests: XCTestCase {
    func testNavigateToArticlesSetsSelectedSource() {
        let router = AppRouter()
        let source = NewsSource(
            id: "bbc",
            name: "BBC",
            description: "News",
            category: "general",
            language: "en",
            url: nil
        )

        router.navigateToArticles(for: source)

        XCTAssertEqual(router.selectedSource?.id, "bbc")
        XCTAssertEqual(router.selectedSource?.name, "BBC")
    }
}
