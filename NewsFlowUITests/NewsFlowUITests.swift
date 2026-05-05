import XCTest

final class NewsFlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UITest.ResetState", "UITest.MockNews"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testSourceSelectionShowsArticlesAndReadingListToggleChangesText() {
        // Arrange
        let sourceButton = app.buttons["source.card.bbc-news"]
        XCTAssertTrue(sourceButton.waitForExistence(timeout: 10))

        // Act
        sourceButton.tap()

        // Assert
        let readingListButton = app.buttons["article.bookmark"].firstMatch
        XCTAssertTrue(readingListButton.waitForExistence(timeout: 10))
        XCTAssertTrue(readingListButton.hasAnyLabel(["Add to Reading List", "Okuma listeme ekle"]))

        readingListButton.tap()
        XCTAssertTrue(
            readingListButton.waitForAnyLabel(
                ["Remove from Reading List", "Okuma listemden çıkar"],
                timeout: 3
            )
        )
    }

    @MainActor
    func testCategoryMultiSelectionFiltersSourcesClientSide() {
        // Arrange
        let businessChip = app.buttons["category.chip.business"]
        let generalChip = app.buttons["category.chip.general"]
        XCTAssertTrue(businessChip.waitForExistence(timeout: 10))
        XCTAssertTrue(generalChip.waitForExistence(timeout: 10))

        // Act
        businessChip.tap()
        generalChip.tap()

        // Assert
        XCTAssertTrue(app.buttons["source.card.bloomberg"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["source.card.bbc-news"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["source.card.techcrunch"].exists)
    }
}

private extension XCUIElement {
    func hasAnyLabel(_ labels: [String]) -> Bool {
        labels.contains(label)
    }

    func waitForAnyLabel(_ labels: [String], timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate { element, _ in
            guard let element = element as? XCUIElement else { return false }
            return labels.contains(element.label)
        }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }
}
