import XCTest

// MARK: - Base Page Object

/// Base class for all page objects. Provides common waiting and interaction utilities.
class PageObject {
    let app: XCUIApplication
    let timeout: TimeInterval = 5

    init(app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func waitForExistence(_ element: XCUIElement, timeout: TimeInterval? = nil) -> Bool {
        element.waitForExistence(timeout: timeout ?? self.timeout)
    }

    @discardableResult
    func waitForHittable(_ element: XCUIElement, timeout: TimeInterval? = nil) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND hittable == true"),
            object: element
        )
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout ?? self.timeout)
        return result == .completed
    }

    func tapWhenReady(_ element: XCUIElement) {
        XCTAssertTrue(waitForHittable(element), "Element not hittable")
        element.tap()
    }

    func swipeToRefresh(scrollView: XCUIElement) {
        let start = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        let finish = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
        start.press(forDuration: 0.1, thenDragTo: finish)
    }
}

// MARK: - Sources Screen Page Object

final class SourcesScreen: PageObject {
    var isDisplayed: Bool {
        waitForExistence(app.scrollViews["sources.list"])
    }

    var settingsButton: XCUIElement {
        app.buttons["gearshape"]
    }

    func sourceCard(named name: String) -> XCUIElement {
        app.staticTexts[name]
    }

    func categoryChip(named name: String) -> XCUIElement {
        app.buttons["category.chip.\(name)"]
    }

    @discardableResult
    func tapSource(named name: String) -> ArticlesScreen {
        tapWhenReady(sourceCard(named: name))
        return ArticlesScreen(app: app)
    }

    @discardableResult
    func tapSettings() -> SettingsScreen {
        tapWhenReady(settingsButton)
        return SettingsScreen(app: app)
    }

    func tapCategory(named name: String) {
        tapWhenReady(categoryChip(named: name))
    }
}

// MARK: - Articles Screen Page Object

final class ArticlesScreen: PageObject {
    var isDisplayed: Bool {
        waitForExistence(app.scrollViews["articles.list"])
    }

    func backButton() -> XCUIElement {
        app.navigationBars.buttons.firstMatch
    }

    var scrollView: XCUIElement {
        app.scrollViews["articles.list"]
    }

    var loadMoreButton: XCUIElement {
        app.buttons["articles.loadMore"]
    }

    func articleCard(at index: Int) -> XCUIElement {
        app.buttons.matching(identifier: "article.bookmark").element(boundBy: index)
    }

    @discardableResult
    func goBack() -> SourcesScreen {
        tapWhenReady(backButton())
        return SourcesScreen(app: app)
    }

    func pullToRefresh() {
        swipeToRefresh(scrollView: scrollView)
    }

    func tapLoadMore() {
        tapWhenReady(loadMoreButton)
    }
}

// MARK: - Settings Screen Page Object

final class SettingsScreen: PageObject {
    var isDisplayed: Bool {
        waitForExistence(app.navigationBars["Settings"])
    }

    var backButton: XCUIElement {
        app.navigationBars.buttons.firstMatch
    }

    func themeRow(_ theme: String) -> XCUIElement {
        app.buttons["theme.row.\(theme)"]
    }

    func languageRow(_ language: String) -> XCUIElement {
        app.buttons["language.row.\(language)"]
    }

    @discardableResult
    func goBack() -> SourcesScreen {
        tapWhenReady(backButton)
        return SourcesScreen(app: app)
    }

    func selectTheme(_ theme: String) {
        tapWhenReady(themeRow(theme))
    }

    func selectLanguage(_ language: String) {
        tapWhenReady(languageRow(language))
    }
}
