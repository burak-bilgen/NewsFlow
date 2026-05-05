import XCTest

// MARK: - NewsFlow UI Tests (POM-based)

/// Professional UI tests using Page Object Model pattern.
/// Tests cover the full user journey with stable wait helpers.
final class NewsFlowUITests: XCTestCase {
    private var app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UITest.ResetState", "UITest.MockNews"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
    }

    // MARK: - Source Browsing

    @MainActor
    func testAppLaunchShowsSourcesList() {
        let sources = SourcesScreen(app: app)
        XCTAssertTrue(sources.isDisplayed, "Sources screen should be visible")
        XCTAssertTrue(sources.waitForExistence(sources.sourceCard(named: "BBC News")))
    }

    @MainActor
    func testCategorySelectionFiltersSources() {
        let sources = SourcesScreen(app: app)
        XCTAssertTrue(sources.isDisplayed)

        let chip = sources.categoryChip(named: "technology")
        XCTAssertTrue(sources.waitForExistence(chip))
        sources.tapCategory(named: "technology")

        // Allow animation to settle
        let expectation = expectation(description: "Filter animation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { expectation.fulfill() }
        wait(for: [expectation], timeout: 2)

        XCTAssertTrue(sources.sourceCard(named: "TechCrunch").exists)
    }

    @MainActor
    func testSelectingSourceOpensArticles() {
        let sources = SourcesScreen(app: app)
        let articles = sources.tapSource(named: "BBC News")

        XCTAssertTrue(articles.isDisplayed, "Articles screen should be visible")
        XCTAssertTrue(articles.waitForExistence(app.navigationBars["BBC News"]))
    }

    @MainActor
    func testPullToRefreshArticles() {
        let sources = SourcesScreen(app: app)
        let articles = sources.tapSource(named: "BBC News")
        XCTAssertTrue(articles.isDisplayed)

        articles.pullToRefresh()

        XCTAssertTrue(articles.waitForExistence(articles.scrollView))
    }

    // MARK: - Settings

    @MainActor
    func testSettingsNavigation() {
        let sources = SourcesScreen(app: app)
        let settings = sources.tapSettings()

        XCTAssertTrue(settings.isDisplayed, "Settings screen should be visible")

        let _ = settings.goBack()
        XCTAssertTrue(sources.isDisplayed, "Should return to sources screen")
    }

    @MainActor
    func testThemeSelection() {
        let sources = SourcesScreen(app: app)
        let settings = sources.tapSettings()

        settings.selectTheme("dark")

        // Verify theme was selected (checkmark appears)
        XCTAssertTrue(settings.themeRow("dark").images["checkmark.circle.fill"].exists)

        let _ = settings.goBack()
    }

    // MARK: - Error Handling

    @MainActor
    func testErrorSimulationAndRetry() {
        let sources = SourcesScreen(app: app)
        let articles = sources.tapSource(named: "BBC News")
        XCTAssertTrue(articles.isDisplayed)

        articles.pullToRefresh()

        // If alert appears, dismiss by tapping retry
        let alert = app.alerts.firstMatch
        if alert.waitForExistence(timeout: 5) {
            let retryButton = alert.buttons.element(boundBy: 0)
            retryButton.tap()
            XCTAssertTrue(articles.waitForExistence(articles.scrollView))
        }
    }

    // MARK: - Carousel

    @MainActor
    func testCarouselPageIndicatorExists() {
        let sources = SourcesScreen(app: app)
        let articles = sources.tapSource(named: "BBC News")
        XCTAssertTrue(articles.isDisplayed)

        let pageIndicator = app.pageIndicators.firstMatch
        XCTAssertTrue(pageIndicator.waitForExistence(timeout: 5), "Carousel page indicator should exist")
    }
}
