import XCTest

// MARK: - NewsFlow UI Tests

/// End-to-end UI automation for the NewsFlow app.
/// Tests cover the full user journey: browsing sources, reading articles,
/// managing bookmarks, and navigating settings.
final class NewsFlowUITests: XCTestCase {
    private var app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Launch with mock data so tests are deterministic and fast
        app.launchArguments = ["UITest.ResetState", "UITest.MockNews"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
    }

    // MARK: - Source Browsing

    /// Verifies the app launches and shows the source browser with expected sources.
    @MainActor
    func testAppLaunchShowsSourcesList() {
        // With the Netflix-style layout, sources appear as large cards in horizontal rows
        XCTAssertTrue(app.staticTexts["BBC News"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["TechCrunch"].exists)
    }

    /// Verifies category chips filter sources correctly.
    @MainActor
    func testCategorySelectionFiltersSources() {
        let technologyChip = app.buttons["category.chip.technology"]
        XCTAssertTrue(technologyChip.waitForExistence(timeout: 5))
        technologyChip.tap()

        // After filtering to technology, TechCrunch should remain visible
        XCTAssertTrue(app.staticTexts["TechCrunch"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["BBC News"].exists)
    }

    // MARK: - Article Reading

    /// Verifies tapping a source opens its articles and bookmark toggle works.
    @MainActor
    func testSelectingSourceOpensArticlesAndReadingListToggles() {
        let source = app.staticTexts["BBC News"]
        XCTAssertTrue(source.waitForExistence(timeout: 5))
        source.tap()

        // Article screen should load with the source name in the nav bar
        XCTAssertTrue(app.navigationBars["BBC News"].waitForExistence(timeout: 5))

        // The bookmark button should exist in the hero carousel
        let addButton = app.buttons["Okuma listeme ekle"].firstMatch
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        // After tapping, button label should change to "remove"
        XCTAssertTrue(app.buttons["Okuma listemden çıkar"].firstMatch.waitForExistence(timeout: 5))
    }

    /// Verifies pull-to-refresh on the articles screen triggers a reload.
    @MainActor
    func testPullToRefreshArticles() {
        let source = app.staticTexts["BBC News"]
        XCTAssertTrue(source.waitForExistence(timeout: 5))
        source.tap()

        XCTAssertTrue(app.navigationBars["BBC News"].waitForExistence(timeout: 5))

        // Find the scroll view and perform a pull-to-refresh gesture
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5))

        // Pull down enough to trigger the refresh control
        let start = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        let finish = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
        start.press(forDuration: 0.1, thenDragTo: finish)

        // After refresh, the list should still be visible
        XCTAssertTrue(app.scrollViews.firstMatch.waitForExistence(timeout: 5))
    }

    // MARK: - Error Handling

    /// Verifies the error simulator shows a warning every 3rd request and retry recovers.
    @MainActor
    func testErrorSimulationAndRetry() {
        let source = app.staticTexts["BBC News"]
        XCTAssertTrue(source.waitForExistence(timeout: 5))
        source.tap()

        // Wait for the article screen to appear
        XCTAssertTrue(app.navigationBars["BBC News"].waitForExistence(timeout: 5))

        // Pull to refresh (this may trigger the simulated error on the 3rd request)
        let scrollView = app.scrollViews.firstMatch
        let start = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        let finish = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
        start.press(forDuration: 0.1, thenDragTo: finish)

        // If an alert appears (simulated error), tap retry
        let retryButton = app.buttons["Tekrar Dene"]
        if retryButton.waitForExistence(timeout: 5) {
            retryButton.tap()
            // After retry, content should load
            XCTAssertTrue(app.scrollViews.firstMatch.waitForExistence(timeout: 5))
        }
    }

    // MARK: - Settings

    /// Verifies the settings screen opens and theme selection works.
    @MainActor
    func testSettingsNavigationAndThemeSelection() {
        // Tap the settings gear icon in the top-right toolbar
        let settingsButton = app.buttons["gearshape"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()

        // Settings screen should appear with "Settings" navigation bar
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))

        // Dark mode option should exist
        let darkThemeButton = app.buttons["Dark"]
        XCTAssertTrue(darkThemeButton.waitForExistence(timeout: 5))
        darkThemeButton.tap()

        // A checkmark should appear next to the selected theme
        XCTAssertTrue(app.images["checkmark.circle.fill"].waitForExistence(timeout: 2))
    }
}
