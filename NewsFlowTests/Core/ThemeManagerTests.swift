import XCTest
@testable import NewsFlow

@MainActor
final class ThemeManagerTests: XCTestCase {
    private var manager: ThemeManager!
    private let key = "app.theme.preference"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: key)
        manager = ThemeManager()
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: key)
        manager = nil
        super.tearDown()
    }

    func testDefaultThemeIsLight() {
        XCTAssertEqual(manager.currentTheme, .light)
    }

    func testSetThemeUpdatesCurrentTheme() {
        manager.setTheme(.dark)
        XCTAssertEqual(manager.currentTheme, .dark)
    }

    func testSetThemePersistsToUserDefaults() {
        manager.setTheme(.system)
        XCTAssertEqual(UserDefaults.standard.string(forKey: key), "system")
    }

    func testSetSameThemeDoesNothing() {
        manager.setTheme(.light)
        XCTAssertEqual(manager.currentTheme, .light)
    }
}
