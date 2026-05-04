import XCTest
@testable import NewsFlow

final class SourceFilteringTests: XCTestCase {
    private let sources = [
        NewsSource(id: "bbc", name: "BBC", description: "A", category: "general", language: "en"),
        NewsSource(id: "tc", name: "TechCrunch", description: "B", category: "technology", language: "en"),
        NewsSource(id: "espn", name: "ESPN", description: "C", category: "sports", language: "en"),
        NewsSource(id: "fr", name: "French", description: "D", category: "general", language: "fr")
    ]

    func testEnglishSourceFilteringRemovesNonEnglishSources() {
        let result = SourceFilterService.englishSources(from: sources)

        XCTAssertEqual(result.map(\.id), ["bbc", "espn", "tc"])
    }

    func testCategoryExtractionUsesEnglishSourcesOnly() {
        let result = SourceFilterService.categories(from: sources)

        XCTAssertEqual(result, ["general", "sports", "technology"])
    }

    func testMultiCategoryFilteringReturnsSourcesInAnySelectedCategory() {
        let result = SourceFilterService.filter(
            sources: sources,
            selectedCategories: ["general", "technology"]
        )

        XCTAssertEqual(result.map(\.id), ["bbc", "tc"])
    }
}
