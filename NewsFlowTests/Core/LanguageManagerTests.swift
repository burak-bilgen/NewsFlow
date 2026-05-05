import XCTest
@testable import NewsFlow

@MainActor
final class LanguageManagerTests: XCTestCase {
    private var manager: LanguageManager!
    private let key = "app.language.preference"
    private let appleLanguagesKey = "AppleLanguages"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.removeObject(forKey: appleLanguagesKey)
        manager = LanguageManager()
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.removeObject(forKey: appleLanguagesKey)
        manager = nil
        super.tearDown()
    }

    func testDefaultLanguageIsEnglish() {
        XCTAssertEqual(manager.currentLanguage, .english)
    }

    func testSetLanguageUpdatesCurrentLanguage() {
        manager.setLanguage(.turkish)
        XCTAssertEqual(manager.currentLanguage, .turkish)
    }

    func testSetLanguagePersistsToUserDefaults() {
        manager.setLanguage(.turkish)
        XCTAssertEqual(UserDefaults.standard.string(forKey: key), "tr")
        XCTAssertEqual(UserDefaults.standard.object(forKey: appleLanguagesKey) as? [String], ["tr"])
    }

    func testSetSameLanguageDoesNothing() {
        manager.setLanguage(.english)
        XCTAssertEqual(manager.currentLanguage, .english)
    }
}
