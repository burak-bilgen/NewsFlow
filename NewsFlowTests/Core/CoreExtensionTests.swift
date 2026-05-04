import XCTest
@testable import NewsFlow

final class StringBlankTests: XCTestCase {
    func testNilIfBlankReturnsNilForEmptyString() {
        XCTAssertNil("".nilIfBlank)
    }

    func testNilIfBlankReturnsNilForWhitespaceOnly() {
        XCTAssertNil("   ".nilIfBlank)
        XCTAssertNil("\t\n".nilIfBlank)
    }

    func testNilIfBlankReturnsValueForNonBlank() {
        XCTAssertEqual("hello".nilIfBlank, "hello")
        XCTAssertEqual("  hello  ".nilIfBlank, "hello")
    }
}

final class ArticleDateFormatterTests: XCTestCase {
    func testParseISO8601WithFractionalSeconds() {
        let date = ArticleDateFormatter.parse("2026-05-04T12:00:00.123Z")
        XCTAssertNotNil(date)
    }

    func testParseISO8601WithoutFractionalSeconds() {
        let date = ArticleDateFormatter.parse("2026-05-04T12:00:00Z")
        XCTAssertNotNil(date)
    }

    func testParseReturnsNilForNil() {
        XCTAssertNil(ArticleDateFormatter.parse(nil))
    }

    func testParseReturnsNilForInvalidString() {
        XCTAssertNil(ArticleDateFormatter.parse("not-a-date"))
    }

    func testDisplayStringProducesFormattedOutput() {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let result = ArticleDateFormatter.displayString(from: date)
        XCTAssertFalse(result.isEmpty)
    }

    func testDisplayStringReturnsUnknownForNil() {
        let result = ArticleDateFormatter.displayString(from: nil)
        XCTAssertEqual(result, L10n.text("article.date.unknown"))
    }
}

final class NewsAPIErrorTests: XCTestCase {
    func testUserMessages() {
        XCTAssertEqual(NewsAPIError.missingAPIKey.userMessage, L10n.text("error.missingApiKey"))
        XCTAssertEqual(NewsAPIError.network.userMessage, L10n.text("error.network"))
        XCTAssertEqual(NewsAPIError.invalidURL.userMessage, L10n.text("error.generic"))
        XCTAssertEqual(NewsAPIError.invalidResponse.userMessage, L10n.text("error.generic"))
        XCTAssertEqual(NewsAPIError.emptyResponse.userMessage, L10n.text("error.generic"))
        XCTAssertEqual(NewsAPIError.decoding.userMessage, L10n.text("error.generic"))
        XCTAssertEqual(NewsAPIError.apiStatus(code: "1", message: "m").userMessage, L10n.text("error.generic"))
        XCTAssertEqual(NewsAPIError.cancelled.userMessage, "")
    }

    func testDebugDescriptions() {
        XCTAssertFalse(NewsAPIError.invalidURL.debugDescription.isEmpty)
        XCTAssertFalse(NewsAPIError.network.debugDescription.isEmpty)
        XCTAssertFalse(NewsAPIError.cancelled.debugDescription.isEmpty)
    }

    func testAPIStatusDescription() {
        let error = NewsAPIError.apiStatus(code: "rateLimited", message: "Too many requests")
        XCTAssertTrue(error.debugDescription.contains("rateLimited"))
        XCTAssertTrue(error.debugDescription.contains("Too many requests"))
    }
}

final class APIConfigTests: XCTestCase {
    func testBaseURLIsNewsAPI() {
        XCTAssertEqual(APIConfig.baseURL?.host, "newsapi.org")
        XCTAssertEqual(APIConfig.baseURL?.scheme, "https")
    }

    func testAPIKeyIsConfiguredFromInfoPlist() {
        let key = APIConfig.apiKey
        XCTAssertNotNil(key)
        XCTAssertFalse(key?.isEmpty ?? true)
    }
}

final class SourceDTOEdgeCaseTests: XCTestCase {
    func testDomainModelReturnsNilForNilID() {
        let dto = SourceDTO(id: nil, name: "Test", description: "Desc", category: "tech", language: "en")
        XCTAssertNil(dto.domainModel())
    }

    func testDomainModelReturnsNilForEmptyID() {
        let dto = SourceDTO(id: "", name: "Test", description: "Desc", category: "tech", language: "en")
        XCTAssertNil(dto.domainModel())
    }

    func testDomainModelUsesIDWhenNameIsNil() {
        let dto = SourceDTO(id: "test", name: nil, description: nil, category: nil, language: nil)
        let model = dto.domainModel()
        XCTAssertEqual(model?.name, "test")
    }

    func testDomainModelDefaultsCategory() {
        let dto = SourceDTO(id: "test", name: "Test", description: "D", category: nil, language: "en")
        let model = dto.domainModel()
        XCTAssertEqual(model?.category, "general")
    }
}

final class ArticleDTOEdgeCaseTests: XCTestCase {
    func testDomainModelUsesFallbackSourceIDWhenSourceIDIsNil() {
        let dto = ArticleDTO(
            source: nil,
            title: "Title",
            url: nil,
            urlToImage: nil,
            publishedAt: nil
        )
        let model = dto.domainModel(fallbackSourceID: "fallback")
        XCTAssertEqual(model?.sourceID, "fallback")
    }

    func testDomainModelUsesUntitledWhenTitleIsNil() {
        let dto = ArticleDTO(source: nil, title: nil, url: nil, urlToImage: nil, publishedAt: nil)
        let model = dto.domainModel(fallbackSourceID: "f")
        XCTAssertEqual(model?.title, L10n.text("article.title.untitled"))
    }
}

final class ReadingListToggleTests: XCTestCase {
    func testToggleAddsAndReturnsTrue() async throws {
        let repo = UserDefaultsReadingListRepository(userDefaults: try XCTUnwrap(
            UserDefaults(suiteName: "NewsFlowTests.Toggle.\(UUID().uuidString)")
        ))
        let article = TestFactory.article(id: "toggle-test", title: "T", publishedAt: Date())

        let result = try await repo.toggle(article)
        XCTAssertTrue(result)
        let isSaved = await repo.isSaved(articleID: article.id)
        XCTAssertTrue(isSaved)
    }

    func testToggleRemovesAndReturnsFalse() async throws {
        let suiteName = "NewsFlowTests.ToggleRemove.\(UUID().uuidString)"
        let repo = UserDefaultsReadingListRepository(userDefaults: try XCTUnwrap(
            UserDefaults(suiteName: suiteName)
        ))
        let article = TestFactory.article(id: "toggle-remove", title: "T", publishedAt: Date())

        try await repo.add(article)
        let removeResult = try await repo.toggle(article)
        XCTAssertFalse(removeResult)
    }
}
