import XCTest
@testable import NewsApto

final class GuardianEndpointTests: XCTestCase {
    func testSearchEndpointPath() {
        let endpoint = GuardianEndpoint.search(query: nil, page: 1, pageSize: 20, section: nil)
        XCTAssertEqual(endpoint.path, "/search")
    }

    func testSearchEndpointQueryItems() {
        let endpoint = GuardianEndpoint.search(query: "bitcoin", page: 2, pageSize: 10, section: "technology")
        let items = Dictionary(uniqueKeysWithValues: endpoint.queryItems.map { ($0.name, $0.value ?? "") })

        XCTAssertEqual(items["page"], "2")
        XCTAssertEqual(items["page-size"], "10")
        XCTAssertEqual(items["q"], "bitcoin")
        XCTAssertEqual(items["section"], "technology")
        XCTAssertNotNil(items["show-fields"])
        XCTAssertNotNil(items["show-blocks"])
    }

    func testSearchEndpointNilQueryExcludesParam() {
        let endpoint = GuardianEndpoint.search(query: nil, page: 1, pageSize: 20, section: nil)
        let names = Set(endpoint.queryItems.map(\.name))

        XCTAssertFalse(names.contains("q"))
        XCTAssertFalse(names.contains("section"))
    }
}

final class GuardianClientTests: XCTestCase {
    private func makeHTTPResponse(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: "https://content.guardianapis.com/search")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
    }

    private func makeGuardianSearchJSON(results: [[String: Any]]) -> Data {
        let json: [String: Any] = [
            "response": [
                "status": "ok",
                "total": results.count,
                "results": results
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    private func makeArticleJSON(id: String = "guardian/test-id", title: String = "Test Article") -> [String: Any] {
        [
            "id": id,
            "type": "article",
            "sectionId": "technology",
            "sectionName": "Technology",
            "webPublicationDate": "2026-05-13T10:00:00Z",
            "webTitle": title,
            "webUrl": "https://www.theguardian.com/\(id)",
            "fields": [
                "trailText": "A test article.",
                "thumbnail": "https://media.guardian.com/thumb.jpg",
                "bodyText": "Full body text."
            ],
            "blocks": [
                "main": [
                    "elements": [
                        [
                            "type": "image",
                            "assets": [
                                ["file": "https://media.guardian.com/img.jpg", "typeData": ["width": 1000, "height": 600]]
                            ]
                        ]
                    ]
                ]
            ]
        ]
    }

    func testSearchSuccessReturnsArticles() async throws {
        let results = [makeArticleJSON(), makeArticleJSON(id: "guardian/test-2", title: "Second Article")]
        let data = makeGuardianSearchJSON(results: results)
        let response = makeHTTPResponse(statusCode: 200)
        let session = MockURLSession(result: .success((data, response)))
        let client = GuardianClient(
            session: session,
            config: APIConfig.GuardianConfig(
                baseURL: URL(string: "https://content.guardianapis.com"),
                apiKey: "test-key"
            )
        )

        let articles = try await client.search(query: nil, page: 1, pageSize: 20, section: nil)

        XCTAssertEqual(articles.count, 2)
        XCTAssertEqual(articles.first?.title, "Test Article")
        XCTAssertEqual(articles.first?.sourceName, "The Guardian")
        XCTAssertEqual(articles.first?.sourceID, "guardian")
        XCTAssertEqual(articles.first?.apiSource, .guardian)
    }

    func testSearchReturnsEmptyForNoResults() async throws {
        let data = makeGuardianSearchJSON(results: [])
        let response = makeHTTPResponse(statusCode: 200)
        let session = MockURLSession(result: .success((data, response)))
        let client = GuardianClient(
            session: session,
            config: APIConfig.GuardianConfig(
                baseURL: URL(string: "https://content.guardianapis.com"),
                apiKey: "test-key"
            )
        )

        let articles = try await client.search(query: "nonexistent", page: 1, pageSize: 20, section: nil)

        XCTAssertTrue(articles.isEmpty)
    }

    func testSearchThrowsForInvalidBaseURL() async {
        let client = GuardianClient(
            session: MockURLSession(result: .failure(NewsAPIError.network)),
            config: APIConfig.GuardianConfig(baseURL: nil, apiKey: "test-key")
        )

        do {
            _ = try await client.search(query: nil, page: 1, pageSize: 20, section: nil)
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(error as? NewsAPIError, .invalidURL)
        }
    }

    func testSearchThrowsForMissingAPIKey() async {
        let client = GuardianClient(
            session: MockURLSession(result: .failure(NewsAPIError.network)),
            config: APIConfig.GuardianConfig(
                baseURL: URL(string: "https://content.guardianapis.com"),
                apiKey: nil
            )
        )

        do {
            _ = try await client.search(query: nil, page: 1, pageSize: 20, section: nil)
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(error as? NewsAPIError, .missingAPIKey)
        }
    }

    func testSearchThrowsForEmptyAPIKey() async {
        let client = GuardianClient(
            session: MockURLSession(result: .failure(NewsAPIError.network)),
            config: APIConfig.GuardianConfig(
                baseURL: URL(string: "https://content.guardianapis.com"),
                apiKey: ""
            )
        )

        do {
            _ = try await client.search(query: nil, page: 1, pageSize: 20, section: nil)
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(error as? NewsAPIError, .missingAPIKey)
        }
    }

    func testSearchThrowsForNonOKStatus() async {
        let json: [String: Any] = ["response": ["status": "error", "total": 0, "results": []]]
        let data = try! JSONSerialization.data(withJSONObject: json)
        let response = makeHTTPResponse(statusCode: 200)
        let session = MockURLSession(result: .success((data, response)))
        let client = GuardianClient(
            session: session,
            config: APIConfig.GuardianConfig(
                baseURL: URL(string: "https://content.guardianapis.com"),
                apiKey: "test-key"
            )
        )

        do {
            _ = try await client.search(query: nil, page: 1, pageSize: 20, section: nil)
            XCTFail("Expected error")
        } catch {
            guard let newsError = error as? NewsAPIError else {
                XCTFail("Expected NewsAPIError, got \(error)")
                return
            }
            if case .apiStatus = newsError {
                XCTAssertTrue(true)
            } else {
                XCTFail("Expected apiStatus error, got \(newsError)")
            }
        }
    }

    func testSearchImageURLFromFieldsThumbnail() async throws {
        let articleJSON: [String: Any] = [
            "id": "guardian/img-test",
            "type": "article",
            "webPublicationDate": "2026-05-13T10:00:00Z",
            "webTitle": "Image Test",
            "webUrl": "https://www.theguardian.com/test",
            "fields": [
                "thumbnail": "https://media.guardian.com/thumb.jpg",
                "trailText": "Has thumbnail."
            ]
        ]
        let data = makeGuardianSearchJSON(results: [articleJSON])
        let response = makeHTTPResponse(statusCode: 200)
        let session = MockURLSession(result: .success((data, response)))
        let client = GuardianClient(
            session: session,
            config: APIConfig.GuardianConfig(
                baseURL: URL(string: "https://content.guardianapis.com"),
                apiKey: "test-key"
            )
        )

        let articles = try await client.search(query: nil, page: 1, pageSize: 20, section: nil)

        XCTAssertEqual(articles.first?.imageURL?.absoluteString, "https://media.guardian.com/thumb.jpg")
    }

    func testSearchImageURLFallbackToBlocks() async throws {
        let articleJSON: [String: Any] = [
            "id": "guardian/blocks-test",
            "type": "article",
            "webPublicationDate": "2026-05-13T10:00:00Z",
            "webTitle": "Blocks Test",
            "webUrl": "https://www.theguardian.com/test",
            "blocks": [
                "main": [
                    "elements": [
                        [
                            "type": "image",
                            "assets": [
                                ["file": "https://media.guardian.com/blocks-img.jpg", "typeData": ["width": 800, "height": 500]]
                            ]
                        ]
                    ]
                ]
            ]
        ]
        let data = makeGuardianSearchJSON(results: [articleJSON])
        let response = makeHTTPResponse(statusCode: 200)
        let session = MockURLSession(result: .success((data, response)))
        let client = GuardianClient(
            session: session,
            config: APIConfig.GuardianConfig(
                baseURL: URL(string: "https://content.guardianapis.com"),
                apiKey: "test-key"
            )
        )

        let articles = try await client.search(query: nil, page: 1, pageSize: 20, section: nil)

        XCTAssertEqual(articles.first?.imageURL?.absoluteString, "https://media.guardian.com/blocks-img.jpg")
    }

    func testSearchHTMLEscapingInSnippet() async throws {
        let articleJSON: [String: Any] = [
            "id": "guardian/html-test",
            "type": "article",
            "webPublicationDate": "2026-05-13T10:00:00Z",
            "webTitle": "HTML Test",
            "webUrl": "https://www.theguardian.com/test",
            "fields": [
                "trailText": "<p>HTML <b>content</b> here.</p>",
                "bodyText": "Plain text."
            ]
        ]
        let data = makeGuardianSearchJSON(results: [articleJSON])
        let response = makeHTTPResponse(statusCode: 200)
        let session = MockURLSession(result: .success((data, response)))
        let client = GuardianClient(
            session: session,
            config: APIConfig.GuardianConfig(
                baseURL: URL(string: "https://content.guardianapis.com"),
                apiKey: "test-key"
            )
        )

        let articles = try await client.search(query: nil, page: 1, pageSize: 20, section: nil)

        XCTAssertEqual(articles.first?.description, "HTML content here.")
        XCTAssertEqual(articles.first?.contentSnippet, "HTML content here.")
    }
}
