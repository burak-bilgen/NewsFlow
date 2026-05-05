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
        XCTAssertEqual(components.path, "/v2/top-headlines/sources")
        XCTAssertEqual(queryItems["language"], "en")
        XCTAssertEqual(queryItems["apiKey"], "test-key")
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.timeoutInterval, 12)
    }

    func testEndpointBuildingForTopHeadlines() throws {
        let builder = NewsAPIRequestBuilder(
            baseURLProvider: { URL(string: "https://newsapi.org") },
            apiKeyProvider: { "test-key" }
        )

        let request = try builder.makeRequest(endpoint: .topHeadlines(sourceID: "bbc-news", page: 1, pageSize: 20))
        let components = try XCTUnwrap(
            URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false)
        )
        let queryItems = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") }
        )

        XCTAssertEqual(components.path, "/v2/top-headlines")
        XCTAssertEqual(queryItems["sources"], "bbc-news")
        XCTAssertEqual(queryItems["page"], "1")
        XCTAssertEqual(queryItems["pageSize"], "20")
        XCTAssertNil(queryItems["language"])
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

// MARK: - Mock URLSession

actor MockURLSession: URLSessionProtocol {
    var result: Result<(Data, URLResponse), Error>

    init(result: Result<(Data, URLResponse), Error>) {
        self.result = result
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try result.get()
    }
}

// MARK: - NewsAPIClient Tests

final class NewsAPIClientTests: XCTestCase {
    private func makeHTTPResponse(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: "https://newsapi.org/v2/top-headlines")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
    }

    private func makeClient(
        sessionResult: Result<(Data, URLResponse), Error>,
        apiKey: String = "test-key"
    ) -> NewsAPIClient {
        let session = MockURLSession(result: sessionResult)
        let builder = NewsAPIRequestBuilder(
            baseURLProvider: { URL(string: "https://newsapi.org") },
            apiKeyProvider: { apiKey }
        )
        return NewsAPIClient(session: session, requestBuilder: builder)
    }

    func testRequestReturnsDecodedResponse() async throws {
        struct TestResponse: NewsAPIResponseEnvelope {
            let status: String
            let code: String?
            let message: String?
            let value: Int
        }

        let data = """
        {"status": "ok", "value": 42}
        """.data(using: .utf8)!
        let response = makeHTTPResponse(statusCode: 200)
        let client = makeClient(sessionResult: .success((data, response)))

        let result = try await client.request(TestResponse.self, endpoint: .sources)
        XCTAssertEqual(result.status, "ok")
        XCTAssertEqual(result.value, 42)
    }

    func testRequestThrowsInvalidResponseForNonHTTPResponse() async {
        struct TestResponse: NewsAPIResponseEnvelope {
            let status: String
            let code: String?
            let message: String?
        }

        let data = Data("{}".utf8)
        let response = URLResponse(
            url: URL(string: "https://newsapi.org/v2/top-headlines/sources")!,
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: nil
        )
        let client = makeClient(sessionResult: .success((data, response)))

        do {
            _ = try await client.request(TestResponse.self, endpoint: .sources)
            XCTFail("Expected invalidResponse error")
        } catch let error as NewsAPIError {
            XCTAssertEqual(error, .invalidResponse)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRequestThrowsEmptyResponseForEmptyData() async {
        struct TestResponse: NewsAPIResponseEnvelope {
            let status: String
            let code: String?
            let message: String?
        }

        let response = makeHTTPResponse(statusCode: 200)
        let client = makeClient(sessionResult: .success((Data(), response)))

        do {
            _ = try await client.request(TestResponse.self, endpoint: .sources)
            XCTFail("Expected emptyResponse error")
        } catch let error as NewsAPIError {
            XCTAssertEqual(error, .emptyResponse)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRequestThrowsNetworkForURLError() async {
        struct TestResponse: NewsAPIResponseEnvelope {
            let status: String
            let code: String?
            let message: String?
        }

        let client = makeClient(sessionResult: .failure(URLError(.notConnectedToInternet)))

        do {
            _ = try await client.request(TestResponse.self, endpoint: .sources)
            XCTFail("Expected network error")
        } catch let error as NewsAPIError {
            XCTAssertEqual(error, .network)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRequestThrowsCancelledForCancellationError() async {
        struct TestResponse: NewsAPIResponseEnvelope {
            let status: String
            let code: String?
            let message: String?
        }

        let client = makeClient(sessionResult: .failure(CancellationError()))

        do {
            _ = try await client.request(TestResponse.self, endpoint: .sources)
            XCTFail("Expected cancelled error")
        } catch let error as NewsAPIError {
            XCTAssertEqual(error, .cancelled)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRequestThrowsAPIStatusForNonOkStatus() async {
        struct TestResponse: NewsAPIResponseEnvelope {
            let status: String
            let code: String?
            let message: String?
        }

        let data = """
        {"status": "error", "code": "apiKeyInvalid", "message": "API key invalid"}
        """.data(using: .utf8)!
        let response = makeHTTPResponse(statusCode: 200)
        let client = makeClient(sessionResult: .success((data, response)))

        do {
            _ = try await client.request(TestResponse.self, endpoint: .sources)
            XCTFail("Expected apiStatus error")
        } catch let error as NewsAPIError {
            if case .apiStatus(let code, let message) = error {
                XCTAssertEqual(code, "apiKeyInvalid")
                XCTAssertEqual(message, "API key invalid")
            } else {
                XCTFail("Expected apiStatus error, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRequestThrowsDecodingForInvalidJSON() async {
        struct TestResponse: NewsAPIResponseEnvelope {
            let status: String
            let code: String?
            let message: String?
            let value: Int
        }

        let data = Data("not json".utf8)
        let response = makeHTTPResponse(statusCode: 200)
        let client = makeClient(sessionResult: .success((data, response)))

        do {
            _ = try await client.request(TestResponse.self, endpoint: .sources)
            XCTFail("Expected decoding error")
        } catch let error as NewsAPIError {
            XCTAssertEqual(error, .decoding)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRequestThrowsHTTPErrorForNon2xxStatus() async {
        struct TestResponse: NewsAPIResponseEnvelope {
            let status: String
            let code: String?
            let message: String?
        }

        let data = """
        {"status": "error", "code": "rateLimited", "message": "Too many requests"}
        """.data(using: .utf8)!
        let response = makeHTTPResponse(statusCode: 429)
        let client = makeClient(sessionResult: .success((data, response)))

        do {
            _ = try await client.request(TestResponse.self, endpoint: .sources)
            XCTFail("Expected apiStatus error")
        } catch let error as NewsAPIError {
            if case .apiStatus(let code, _) = error {
                XCTAssertEqual(code, "rateLimited")
            } else {
                XCTFail("Expected apiStatus error, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// MARK: - Simulated Network Error Decorator Tests

final class SimulatedNetworkErrorClientDecoratorTests: XCTestCase {
    private struct TestResponse: NewsAPIResponseEnvelope {
        let status: String
        let code: String?
        let message: String?
    }

    private final class StubNewsAPIClient: NewsAPIClientProtocol {
        private(set) var requestCount = 0

        func request<Response: NewsAPIResponseEnvelope>(
            _ responseType: Response.Type,
            endpoint: NewsAPIEndpoint
        ) async throws -> Response {
            requestCount += 1
            let response = TestResponse(status: "ok", code: nil, message: nil)
            guard let typedResponse = response as? Response else {
                throw NewsAPIError.decoding
            }
            return typedResponse
        }
    }

    func testDecoratorFailsExactlyEveryThirdRequest() async throws {
        // Arrange
        let client = StubNewsAPIClient()
        let counter = NetworkRequestFailureCounter(failingInterval: 3)
        let decorator = SimulatedNetworkErrorClientDecorator(
            client: client,
            failureCounter: counter
        )

        // Act & Assert - Request 1 (success)
        let result1 = try await decorator.request(TestResponse.self, endpoint: .sources)
        XCTAssertEqual(result1.status, "ok")

        // Request 2 (success)
        let result2 = try await decorator.request(TestResponse.self, endpoint: .sources)
        XCTAssertEqual(result2.status, "ok")

        // Request 3 (should fail)
        do {
            _ = try await decorator.request(TestResponse.self, endpoint: .sources)
            XCTFail("Expected simulated network error")
        } catch let error as NewsAPIError {
            XCTAssertEqual(error, .simulatedNetwork)
        }
    }

    func testFailureCounterCanReset() async {
        // Arrange
        let counter = NetworkRequestFailureCounter(failingInterval: 3)

        // Act
        await counter.reset()

        // Assert
        let shouldFail = await counter.shouldFailNextRequest()
        XCTAssertFalse(shouldFail)
    }
    
    func testFailureCounterCycles() async {
        let counter = NetworkRequestFailureCounter(failingInterval: 3)
        
        let first = await counter.shouldFailNextRequest()
        let second = await counter.shouldFailNextRequest()
        let third = await counter.shouldFailNextRequest()
        
        XCTAssertFalse(first)
        XCTAssertFalse(second)
        XCTAssertTrue(third)
    }
}

