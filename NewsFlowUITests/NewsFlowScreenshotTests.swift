import XCTest

final class NewsFlowScreenshotTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UITest.ResetState", "UITest.MockNews"]
        setupSnapshot(app)
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testCaptureScreenshots() throws {
        let feed = app.otherElements["feed.screen"]
        XCTAssertTrue(feed.waitForExistence(timeout: 10))
        sleep(2)
        snapshot("01-Feed")

        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            tabBar.buttons.element(boundBy: 1).tap()
            sleep(2)
            snapshot("02-Sources")
        }
    }
}
