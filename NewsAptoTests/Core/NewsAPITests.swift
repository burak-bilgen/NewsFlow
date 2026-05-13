import XCTest
@testable import NewsApto

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

    func testEndpointBuildingForTopHeadlinesWithAllSourcesUsesCountry() throws {
        let builder = NewsAPIRequestBuilder(
            baseURLProvider: { URL(string: "https://newsapi.org") },
            apiKeyProvider: { "test-key" }
        )

        let request = try builder.makeRequest(endpoint: .topHeadlines(sourceID: "all", page: 1, pageSize: 30))
        let components = try XCTUnwrap(
            URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false)
        )
        let queryItems = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") }
        )

        XCTAssertEqual(queryItems["country"], "us")
        XCTAssertNil(queryItems["sources"])
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

// MARK: - Guardian DTO Tests

final class GuardianDTOTests: XCTestCase {
    func testGuardianSearchResponseDecoding() throws {
        let json = """
        {
          "response": {
            "status": "ok",
            "total": 1,
            "results": [
              {
                "id": "world/2026/may/12/test",
                "type": "article",
                "sectionId": "world",
                "sectionName": "World news",
                "webPublicationDate": "2026-05-12T10:00:00Z",
                "webTitle": "Test Guardian Article",
                "webUrl": "https://www.theguardian.com/world/2026/may/12/test",
                "fields": {
                  "trailText": "A test article",
                  "thumbnail": "https://media.guim.co.uk/test.jpg",
                  "bodyText": "Full body text"
                }
              }
            ]
          }
        }
        """
        let data = Data(json.utf8)
        let response = try JSONDecoder().decode(GuardianSearchResponse.self, from: data)

        XCTAssertEqual(response.response.status, "ok")
        XCTAssertEqual(response.response.total, 1)
        XCTAssertEqual(response.response.results.count, 1)

        let dto = try XCTUnwrap(response.response.results.first)
        XCTAssertEqual(dto.id, "world/2026/may/12/test")
        XCTAssertEqual(dto.webTitle, "Test Guardian Article")
        XCTAssertEqual(dto.sectionName, "World news")
    }

    func testGuardianArticleDTODomainModelMapping() throws {
        let json = """
        {
          "id": "world/2026/may/12/test",
          "type": "article",
          "sectionId": "world",
          "sectionName": "World news",
          "webPublicationDate": "2026-05-12T10:00:00Z",
          "webTitle": "Test Guardian Article",
          "webUrl": "https://www.theguardian.com/world/2026/may/12/test",
          "fields": {
            "trailText": "A test article",
            "thumbnail": "https://media.guim.co.uk/test.jpg"
          }
        }
        """
        let data = Data(json.utf8)
        let dto = try JSONDecoder().decode(GuardianArticleDTO.self, from: data)
        let article = dto.domainModel()

        XCTAssertEqual(article.id, "guardian-world/2026/may/12/test")
        XCTAssertEqual(article.sourceID, "guardian")
        XCTAssertEqual(article.title, "Test Guardian Article")
        XCTAssertEqual(article.sourceName, "The Guardian")
        XCTAssertEqual(article.apiSource, .guardian)
        XCTAssertNotNil(article.publishedAt)
        XCTAssertNotNil(article.url)
        XCTAssertEqual(article.url?.absoluteString, "https://www.theguardian.com/world/2026/may/12/test")
    }
}

// MARK: - NYT DTO Tests

final class NYTDTOTests: XCTestCase {
    func testNYTSearchResponseDecoding() throws {
        let json = """
        {
          "status": "OK",
          "response": {
            "docs": [
              {
                "_id": "nyt://article/test-id",
                "headline": { "main": "Test NYT Article" },
                "snippet": "A test snippet",
                "lead_paragraph": "A lead paragraph",
                "pub_date": "2026-05-12T10:00:00Z",
                "web_url": "https://www.nytimes.com/2026/05/12/test.html",
                "multimedia": {
                  "caption": "Test caption",
                  "credit": "Test credit",
                  "default": { "url": "https://static01.nyt.com/images/test.jpg", "width": 600, "height": 400 },
                  "thumbnail": { "url": "https://static01.nyt.com/images/test-thumb.jpg", "width": 75, "height": 75 }
                },
                "source": "The New York Times",
                "section_name": "World"
              }
            ]
          }
        }
        """
        let data = Data(json.utf8)
        let response = try JSONDecoder().decode(NYTSearchResponse.self, from: data)

        XCTAssertEqual(response.status, "OK")
        let docs = try XCTUnwrap(response.response?.docs)
        XCTAssertEqual(docs.count, 1)

        let dto = try XCTUnwrap(docs.first)
        XCTAssertEqual(dto._id, "nyt://article/test-id")
        XCTAssertEqual(dto.headline?.main, "Test NYT Article")
        XCTAssertEqual(dto.snippet, "A test snippet")
        XCTAssertEqual(dto.source, "The New York Times")
        XCTAssertEqual(dto.imageURL?.absoluteString, "https://static01.nyt.com/images/test.jpg")
    }

    func testNYTArticleDTODomainModelMapping() throws {
        let json = """
        {
          "_id": "nyt://article/test-id",
          "headline": { "main": "Test NYT Article" },
          "snippet": "A test snippet",
          "pub_date": "2026-05-12T10:00:00Z",
          "web_url": "https://www.nytimes.com/2026/05/12/test.html",
          "multimedia": {
            "default": { "url": "https://static01.nyt.com/images/test.jpg", "width": 600, "height": 400 }
          },
          "source": "The New York Times",
          "section_name": "World"
        }
        """
        let data = Data(json.utf8)
        let dto = try JSONDecoder().decode(NYTArticleDTO.self, from: data)
        let article = dto.domainModel()

        XCTAssertEqual(article.id, "nyt-nyt://article/test-id")
        XCTAssertEqual(article.sourceID, "nyt")
        XCTAssertEqual(article.title, "Test NYT Article")
        XCTAssertEqual(article.sourceName, "The New York Times")
        XCTAssertEqual(article.apiSource, .nyt)
        XCTAssertNotNil(article.publishedAt)
        XCTAssertNotNil(article.url)
        XCTAssertEqual(article.url?.absoluteString, "https://www.nytimes.com/2026/05/12/test.html")
        XCTAssertEqual(article.imageURL?.absoluteString, "https://static01.nyt.com/images/test.jpg")
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
