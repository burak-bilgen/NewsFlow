import XCTest

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

    @MainActor
    func testAppLaunchShowsSourcesList() {
        XCTAssertTrue(app.navigationBars["Haber Kaynakları"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["BBC News"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["TechCrunch"].exists)
    }

    @MainActor
    func testCategorySelectionFiltersSources() {
        let technologyChip = app.buttons["category.chip.technology"]
        XCTAssertTrue(technologyChip.waitForExistence(timeout: 5))
        technologyChip.tap()

        XCTAssertTrue(app.staticTexts["TechCrunch"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["BBC News"].exists)
    }

    @MainActor
    func testSelectingSourceOpensArticlesAndReadingListToggles() {
        let source = app.staticTexts["BBC News"]
        XCTAssertTrue(source.waitForExistence(timeout: 5))
        source.tap()

        XCTAssertTrue(app.navigationBars["BBC News"].waitForExistence(timeout: 5))
        let addButton = app.buttons["Okuma listeme ekle"].firstMatch
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))

        addButton.tap()

        XCTAssertTrue(app.buttons["Okuma listemden çıkar"].firstMatch.waitForExistence(timeout: 5))
    }
}
