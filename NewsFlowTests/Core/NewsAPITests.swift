import XCTest
@testable import NewsFlow

final class NewsAPIRequestBuilderTests: XCTestCase {
    func testEndpointBuildingForSources() throws {
        let builder = NewsAPIRequestBuilder(
            baseURLProvider: { URL(string: "https://newsapi.org") },
            apiKeyProvider: { "test-key" },
            timeoutInterval: 12
        )

        let request = try builder.makeRequest(endpoint: .sources)
        let components = try XCTUnwrap(
            URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false)
        )
        let queryItems = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") }
        )

        XCTAssertEqual(components.scheme, "https")
        XCTAssertEqual(components.host, "newsapi.org")
        XCTAssertEqual(components.path, "/v2/sources")
        XCTAssertEqual(queryItems["apiKey"], "test-key")
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.timeoutInterval, 12)
    }

    func testEndpointBuildingForTopHeadlines() throws {
        let builder = NewsAPIRequestBuilder(
            baseURLProvider: { URL(string: "https://newsapi.org") },
            apiKeyProvider: { "test-key" }
        )

        let request = try builder.makeRequest(endpoint: .topHeadlines(sourceID: "bbc-news"))
        let components = try XCTUnwrap(
            URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false)
        )
        let queryItems = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") }
        )

        XCTAssertEqual(components.path, "/v2/top-headlines")
        XCTAssertEqual(queryItems["sources"], "bbc-news")
        XCTAssertEqual(queryItems["apiKey"], "test-key")
    }

    func testRequestBuilderThrowsForMissingAPIKey() {
        let builder = NewsAPIRequestBuilder(
            baseURLProvider: { URL(string: "https://newsapi.org") },
            apiKeyProvider: { nil }
        )

        XCTAssertThrowsError(try builder.makeRequest(endpoint: .sources)) { error in
            XCTAssertEqual(error as? NewsAPIError, .missingAPIKey)
        }
    }
}

final class NewsAPIDecodingTests: XCTestCase {
    func testSourcesDTODecoding() throws {
        let json = """
        {
          "status": "ok",
          "sources": [
            {
              "id": "bbc-news",
              "name": "BBC News",
              "description": "News",
              "category": "general",
              "language": "en"
            }
          ]
        }
        """
        let data = Data(json.utf8)

        let response = try JSONDecoder().decode(SourcesResponseDTO.self, from: data)

        XCTAssertEqual(response.status, "ok")
        XCTAssertEqual(response.sources.first?.domainModel()?.id, "bbc-news")
    }

    func testArticlesDTODecoding() throws {
        let json = """
        {
          "status": "ok",
          "totalResults": 1,
          "articles": [
            {
              "source": { "id": "bbc-news", "name": "BBC News" },
              "title": "Headline",
              "url": "https://example.com/story",
              "urlToImage": "https://example.com/image.jpg",
              "publishedAt": "2026-05-04T12:00:00Z"
            }
          ]
        }
        """
        let data = Data(json.utf8)

        let response = try JSONDecoder().decode(ArticlesResponseDTO.self, from: data)
        let article = try XCTUnwrap(response.articles.first?.domainModel(fallbackSourceID: "bbc-news"))

        XCTAssertEqual(response.status, "ok")
        XCTAssertEqual(article.id, "https://example.com/story")
        XCTAssertEqual(article.title, "Headline")
        XCTAssertNotNil(article.publishedAt)
    }
}
