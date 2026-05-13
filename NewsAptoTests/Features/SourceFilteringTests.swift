import XCTest
@testable import NewsApto

final class SourceFilteringTests: XCTestCase {
    private let sources = [
        NewsSource(id: "bbc", name: "BBC", description: "A", category: "general", language: "en", url: nil),
        NewsSource(id: "tc", name: "TechCrunch", description: "B", category: "technology", language: "en", url: nil),
        NewsSource(id: "espn", name: "ESPN", description: "C", category: "sports", language: "en", url: nil),
        NewsSource(id: "fr", name: "French", description: "D", category: "general", language: "fr", url: nil)
    ]

    private let filterService = SourceFilterService()

    func testEnglishSourceFilteringRemovesNonEnglishSources() {
        let result = filterService.englishSources(from: sources)

        XCTAssertEqual(result.map(\.id), ["bbc", "espn", "tc"])
    }

    func testCategoryExtractionUsesEnglishSourcesOnly() {
        let result = filterService.categories(from: sources)

        XCTAssertEqual(result, ["general", "sports", "technology"])
    }

    func testMultiCategoryFilteringReturnsSourcesInAnySelectedCategory() {
        let result = filterService.filter(
            sources: sources,
            selectedCategories: ["general", "technology"]
        )

        XCTAssertEqual(result.map(\.id), ["bbc", "tc"])
    }
}
