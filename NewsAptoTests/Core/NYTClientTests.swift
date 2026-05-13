import XCTest
@testable import NewsApto

final class NYTEndpointTests: XCTestCase {
    func testSearchEndpointPath() {
        let endpoint = NYTEndpoint.search(query: nil, page: 1, section: nil)
        XCTAssertEqual(endpoint.path, "/articlesearch.json")
    }

    func testSearchEndpointQueryItems() {
        let endpoint = NYTEndpoint.search(query: "bitcoin", page: 2, section: "technology")
        let items = Dictionary(uniqueKeysWithValues: endpoint.queryItems.map { ($0.name, $0.value ?? "") })

        XCTAssertEqual(items["page"], "2")
        XCTAssertEqual(items["q"], "bitcoin")
        XCTAssertEqual(items["fq"], "section_name:\"technology\"")
    }

    func testSearchEndpointNilQueryExcludesParam() {
        let endpoint = NYTEndpoint.search(query: nil, page: 1, section: nil)
        let names = Set(endpoint.queryItems.map(\.name))

        XCTAssertFalse(names.contains("q"))
        XCTAssertFalse(names.contains("fq"))
    }

    func testSearchEndpointEmptyQueryExcludesParam() {
        let endpoint = NYTEndpoint.search(query: "", page: 1, section: nil)
        let names = Set(endpoint.queryItems.map(\.name))

        XCTAssertFalse(names.contains("q"))
    }
}

final class NYTClientTests: XCTestCase {
    private func makeHTTPResponse(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: "https://api.nytimes.com/svc/search/v2/articlesearch.json")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
    }

    private func makeNYTSearchJSON(docs: [[String: Any]], hits: Int = 10, offset: Int = 0) -> Data {
        let json: [String: Any] = [
            "status": "OK",
            "response": [
                "docs": docs,
                "meta": ["hits": hits, "offset": offset]
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    private func makeArticleJSON(id: String = "nyt://article/test-id") -> [String: Any] {
        [
            "_id": id,
            "headline": ["main": "Test NYT Article"],
            "snippet": "A test article from NYT.",
            "lead_paragraph": "Lead paragraph content.",
            "pub_date": "2026-05-13T10:00:00+0000",
            "web_url": "https://www.nytimes.com/\(id)",
            "source": "The New York Times",
            "section_name": "Technology",
            "multimedia": [
                "default": ["url": "https://static01.nyt.com/images/2026/05/13/test.jpg", "width": 600, "height": 400],
                "thumbnail": ["url": "https://static01.nyt.com/images/2026/05/13/test-thumb.jpg", "width": 75, "height": 75]
            ]
        ]
    }

    func testSearchSuccessReturnsArticles() async throws {
        let docs = [makeArticleJSON(), makeArticleJSON(id: "nyt://article/test-2")]
        let data = makeNYTSearchJSON(docs: docs)
        let response = makeHTTPResponse(statusCode: 200)
        let session = MockURLSession(result: .success((data, response)))
        let client = NYTClient(
            session: session,
            config: APIConfig.NYTConfig(
                baseURL: URL(string: "https://api.nytimes.com/svc/search/v2"),
                apiKey: "test-key"
            )
        )

        let result = try await client.search(query: nil, page: 1, section: nil)

        XCTAssertEqual(result.articles.count, 2)
        XCTAssertEqual(result.articles.first?.title, "Test NYT Article")
        XCTAssertEqual(result.articles.first?.sourceName, "The New York Times")
        XCTAssertEqual(result.articles.first?.sourceID, "nyt")
        XCTAssertEqual(result.articles.first?.apiSource, .nyt)
    }

    func testSearchHasMoreWhenMorePages() async throws {
        let docs = (0..<10).map { makeArticleJSON(id: "nyt://article/\($0)") }
        let data = makeNYTSearchJSON(docs: docs, hits: 50, offset: 0)
        let response = makeHTTPResponse(statusCode: 200)
        let session = MockURLSession(result: .success((data, response)))
        let client = NYTClient(
            session: session,
            config: APIConfig.NYTConfig(
                baseURL: URL(string: "https://api.nytimes.com/svc/search/v2"),
                apiKey: "test-key"
            )
        )

        let result = try await client.search(query: nil, page: 0, section: nil)

        XCTAssertTrue(result.hasMore)
    }

    func testSearchHasMoreFalseOnLastPage() async throws {
        let docs = (0..<5).map { makeArticleJSON(id: "nyt://article/\($0)") }
        let data = makeNYTSearchJSON(docs: docs, hits: 15, offset: 10)
        let response = makeHTTPResponse(statusCode: 200)
        let session = MockURLSession(result: .success((data, response)))
        let client = NYTClient(
            session: session,
            config: APIConfig.NYTConfig(
                baseURL: URL(string: "https://api.nytimes.com/svc/search/v2"),
                apiKey: "test-key"
            )
        )

        let result = try await client.search(query: nil, page: 1, section: nil)

        XCTAssertFalse(result.hasMore)
    }

    func testSearchHasMoreFalseWhenExactLastPage() async throws {
        let docs = (0..<10).map { makeArticleJSON(id: "nyt://article/\($0)") }
        let data = makeNYTSearchJSON(docs: docs, hits: 10, offset: 0)
        let response = makeHTTPResponse(statusCode: 200)
        let session = MockURLSession(result: .success((data, response)))
        let client = NYTClient(
            session: session,
            config: APIConfig.NYTConfig(
                baseURL: URL(string: "https://api.nytimes.com/svc/search/v2"),
                apiKey: "test-key"
            )
        )

        let result = try await client.search(query: nil, page: 0, section: nil)

        XCTAssertFalse(result.hasMore)
    }

    func testSearchHasMoreFallbackWhenNoMeta() async throws {
        let json: [String: Any] = [
            "status": "OK",
            "response": [
                "docs": (0..<10).map { makeArticleJSON(id: "nyt://article/\($0)") }
            ]
        ]
        let data = try! JSONSerialization.data(withJSONObject: json)
        let response = makeHTTPResponse(statusCode: 200)
        let session = MockURLSession(result: .success((data, response)))
        let client = NYTClient(
            session: session,
            config: APIConfig.NYTConfig(
                baseURL: URL(string: "https://api.nytimes.com/svc/search/v2"),
                apiKey: "test-key"
            )
        )

        let result = try await client.search(query: nil, page: 0, section: nil)

        XCTAssertEqual(result.articles.count, 10)
    }

    func testSearchThrowsForInvalidBaseURL() async {
        let client = NYTClient(
            session: MockURLSession(result: .failure(NewsAPIError.network)),
            config: APIConfig.NYTConfig(baseURL: nil, apiKey: "test-key")
        )

        do {
            _ = try await client.search(query: nil, page: 1, section: nil)
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(error as? NewsAPIError, .invalidURL)
        }
    }

    func testSearchThrowsForMissingAPIKey() async {
        let client = NYTClient(
            session: MockURLSession(result: .failure(NewsAPIError.network)),
            config: APIConfig.NYTConfig(
                baseURL: URL(string: "https://api.nytimes.com/svc/search/v2"),
                apiKey: nil
            )
        )

        do {
            _ = try await client.search(query: nil, page: 1, section: nil)
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(error as? NewsAPIError, .missingAPIKey)
        }
    }

    func testSearchThrowsForFaultResponse() async {
        let json: [String: Any] = [
            "status": "ERROR",
            "fault": ["faultstring": "Invalid API key"]
        ]
        let data = try! JSONSerialization.data(withJSONObject: json)
        let response = makeHTTPResponse(statusCode: 403)
        let session = MockURLSession(result: .success((data, response)))
        let client = NYTClient(
            session: session,
            config: APIConfig.NYTConfig(
                baseURL: URL(string: "https://api.nytimes.com/svc/search/v2"),
                apiKey: "invalid-key"
            )
        )

        do {
            _ = try await client.search(query: nil, page: 1, section: nil)
            XCTFail("Expected error")
        } catch {
            guard let newsError = error as? NewsAPIError else {
                XCTFail("Expected NewsAPIError, got \(error)")
                return
            }
            if case .apiStatus(_, let message) = newsError {
                XCTAssertEqual(message, "Invalid API key")
            } else {
                XCTFail("Expected apiStatus error, got \(newsError)")
            }
        }
    }

    func testSearchReturnsEmptyForNoDocs() async throws {
        let data = makeNYTSearchJSON(docs: [])
        let response = makeHTTPResponse(statusCode: 200)
        let session = MockURLSession(result: .success((data, response)))
        let client = NYTClient(
            session: session,
            config: APIConfig.NYTConfig(
                baseURL: URL(string: "https://api.nytimes.com/svc/search/v2"),
                apiKey: "test-key"
            )
        )

        let result = try await client.search(query: nil, page: 1, section: nil)

        XCTAssertTrue(result.articles.isEmpty)
        XCTAssertFalse(result.hasMore)
    }

    func testSearchImageURLFromDefaultMultimedia() async throws {
        let articleJSON: [String: Any] = [
            "_id": "nyt://article/img-test",
            "headline": ["main": "Image Test"],
            "pub_date": "2026-05-13T10:00:00+0000",
            "web_url": "https://www.nytimes.com/test",
            "multimedia": [
                "default": ["url": "https://static01.nyt.com/images/test/large.jpg", "width": 600, "height": 400],
                "thumbnail": ["url": "https://static01.nyt.com/images/test/thumb.jpg", "width": 75, "height": 75]
            ]
        ]
        let data = makeNYTSearchJSON(docs: [articleJSON])
        let response = makeHTTPResponse(statusCode: 200)
        let session = MockURLSession(result: .success((data, response)))
        let client = NYTClient(
            session: session,
            config: APIConfig.NYTConfig(
                baseURL: URL(string: "https://api.nytimes.com/svc/search/v2"),
                apiKey: "test-key"
            )
        )

        let result = try await client.search(query: nil, page: 1, section: nil)

        XCTAssertEqual(result.articles.first?.imageURL?.absoluteString, "https://static01.nyt.com/images/test/large.jpg")
    }

    func testSearchImageURLFallbackToThumbnail() async throws {
        let articleJSON: [String: Any] = [
            "_id": "nyt://article/fallback-test",
            "headline": ["main": "Fallback Test"],
            "pub_date": "2026-05-13T10:00:00+0000",
            "web_url": "https://www.nytimes.com/test",
            "multimedia": [
                "thumbnail": ["url": "https://static01.nyt.com/images/test/only.jpg", "width": 75, "height": 75]
            ]
        ]
        let data = makeNYTSearchJSON(docs: [articleJSON])
        let response = makeHTTPResponse(statusCode: 200)
        let session = MockURLSession(result: .success((data, response)))
        let client = NYTClient(
            session: session,
            config: APIConfig.NYTConfig(
                baseURL: URL(string: "https://api.nytimes.com/svc/search/v2"),
                apiKey: "test-key"
            )
        )

        let result = try await client.search(query: nil, page: 1, section: nil)

        XCTAssertEqual(result.articles.first?.imageURL?.absoluteString, "https://static01.nyt.com/images/test/only.jpg")
    }

    func testSearchHTMLEscapingInSnippet() async throws {
        let articleJSON: [String: Any] = [
            "_id": "nyt://article/html-test",
            "headline": ["main": "HTML Test"],
            "snippet": "<p>HTML <b>content</b> here.</p>",
            "pub_date": "2026-05-13T10:00:00+0000",
            "web_url": "https://www.nytimes.com/test"
        ]
        let data = makeNYTSearchJSON(docs: [articleJSON])
        let response = makeHTTPResponse(statusCode: 200)
        let session = MockURLSession(result: .success((data, response)))
        let client = NYTClient(
            session: session,
            config: APIConfig.NYTConfig(
                baseURL: URL(string: "https://api.nytimes.com/svc/search/v2"),
                apiKey: "test-key"
            )
        )

        let result = try await client.search(query: nil, page: 1, section: nil)

        XCTAssertEqual(result.articles.first?.description, "HTML content here.")
    }
}
