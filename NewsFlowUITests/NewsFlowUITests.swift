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

    // MARK: - Source Selection

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

    // MARK: - Category Filtering

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

    // MARK: - Carousel

    @MainActor
    func testCarouselExistsOnArticlesScreen() {
        // Arrange
        let sourceButton = app.buttons["source.card.bbc-news"]
        XCTAssertTrue(sourceButton.waitForExistence(timeout: 10))

        // Act
        sourceButton.tap()

        // Assert — carousel should be visible
        let carousel = app.otherElements["articles.carousel"]
        XCTAssertTrue(carousel.waitForExistence(timeout: 10))
    }

    // MARK: - Navigation

    @MainActor
    func testNavigateToArticlesAndBackPreservesSourcesState() {
        // Arrange
        let sourceButton = app.buttons["source.card.bbc-news"]
        XCTAssertTrue(sourceButton.waitForExistence(timeout: 10))

        // Act — navigate to articles
        sourceButton.tap()
        let articleScreen = app.otherElements["articles.screen"]
        XCTAssertTrue(articleScreen.waitForExistence(timeout: 10))

        // Act — navigate back
        app.navigationBars.buttons.firstMatch.tap()

        // Assert — sources should still be visible
        XCTAssertTrue(sourceButton.waitForExistence(timeout: 5))
    }

    // MARK: - Articles List

    @MainActor
    func testArticlesListDisplaysContent() {
        // Arrange
        let sourceButton = app.buttons["source.card.bbc-news"]
        XCTAssertTrue(sourceButton.waitForExistence(timeout: 10))

        // Act
        sourceButton.tap()

        // Assert — article list should have content
        let articlesList = app.scrollViews["articles.list"]
        XCTAssertTrue(articlesList.waitForExistence(timeout: 10))
    }

    // MARK: - Reading List Toggle Persistence

    @MainActor
    func testReadingListTogglePersistsDuringSession() {
        // Arrange
        let sourceButton = app.buttons["source.card.bbc-news"]
        XCTAssertTrue(sourceButton.waitForExistence(timeout: 10))
        sourceButton.tap()

        let readingListButton = app.buttons["article.bookmark"].firstMatch
        XCTAssertTrue(readingListButton.waitForExistence(timeout: 10))

        // Act — save article
        readingListButton.tap()
        XCTAssertTrue(
            readingListButton.waitForAnyLabel(
                ["Remove from Reading List", "Okuma listemden çıkar"],
                timeout: 3
            )
        )

        // Act — navigate back and return
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(sourceButton.waitForExistence(timeout: 5))
        sourceButton.tap()

        // Assert — bookmark should still show "remove" state
        let returnedButton = app.buttons["article.bookmark"].firstMatch
        XCTAssertTrue(returnedButton.waitForExistence(timeout: 10))
        XCTAssertTrue(
            returnedButton.waitForAnyLabel(
                ["Remove from Reading List", "Okuma listemden çıkar"],
                timeout: 3
            )
        )
    }

    // MARK: - Category Deselection

    @MainActor
    func testDeselectingAllCategoriesShowsAllSources() {
        // Arrange
        let generalChip = app.buttons["category.chip.general"]
        XCTAssertTrue(generalChip.waitForExistence(timeout: 10))

        // Act — select then deselect
        generalChip.tap()
        XCTAssertFalse(app.buttons["source.card.techcrunch"].exists)

        generalChip.tap()

        // Assert — all sources should be visible again
        XCTAssertTrue(app.buttons["source.card.bbc-news"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["source.card.techcrunch"].waitForExistence(timeout: 3))
    }
}

// MARK: - XCUIElement Helpers

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

