import XCTest
@testable import NewsApto

final class RetryPolicyTests: XCTestCase {
    func testDefaultValues() {
        let policy = RetryPolicy()
        XCTAssertEqual(policy.maxRetries, 3)
        XCTAssertEqual(policy.baseDelay, 1.0)
        XCTAssertEqual(policy.maxDelay, 30.0)
        XCTAssertTrue(policy.jitter)
    }

    func testDelayExponentialBackoff() {
        var policy = RetryPolicy(maxRetries: 3, baseDelay: 1.0, maxDelay: 30.0, jitter: false)

        let attempt0 = policy.delay(forAttempt: 0)
        let attempt1 = policy.delay(forAttempt: 1)
        let attempt2 = policy.delay(forAttempt: 2)

        XCTAssertEqual(attempt0, 1.0, accuracy: 0.01)
        XCTAssertEqual(attempt1, 2.0, accuracy: 0.01)
        XCTAssertEqual(attempt2, 4.0, accuracy: 0.01)
    }

    func testDelayClampsToMaxDelay() {
        var policy = RetryPolicy(maxRetries: 10, baseDelay: 1.0, maxDelay: 5.0, jitter: false)

        let attempt5 = policy.delay(forAttempt: 5)

        XCTAssertEqual(attempt5, 5.0, accuracy: 0.01)
    }

    func testDelayWithJitter() {
        var policy = RetryPolicy(maxRetries: 3, baseDelay: 1.0, maxDelay: 10.0, jitter: true)

        var delays: Set<TimeInterval> = []
        for _ in 0..<100 {
            delays.insert(policy.delay(forAttempt: 0))
        }

        XCTAssertGreaterThan(delays.count, 1)
    }

    func testDelayWithJitterWithinRange() {
        var policy = RetryPolicy(maxRetries: 3, baseDelay: 1.0, maxDelay: 10.0, jitter: true)

        for _ in 0..<100 {
            let delay = policy.delay(forAttempt: 0)
            XCTAssertGreaterThanOrEqual(delay, 1.0)
            XCTAssertLessThanOrEqual(delay, 1.3)
        }
    }
}

final class RetryingNewsAPIClientDecoratorTests: XCTestCase {
    private struct TestResponse: NewsAPIResponseEnvelope {
        let status: String
        let code: String?
        let message: String?
    }

    private final class CountedClient: NewsAPIClientProtocol {
        var results: [Result<TestResponse, Error>]
        private(set) var callCount = 0

        init(results: [Result<TestResponse, Error>]) {
            self.results = results
        }

        func request<Response: NewsAPIResponseEnvelope>(_ responseType: Response.Type, endpoint: NewsAPIEndpoint) async throws -> Response {
            defer { callCount += 1 }
            let result = results[min(callCount, results.count - 1)]
            let value = try result.get()
            guard let typed = value as? Response else {
                throw NewsAPIError.decoding
            }
            return typed
        }
    }

    private func makeOKResponse() -> TestResponse {
        TestResponse(status: "ok", code: nil, message: nil)
    }

    func testSuccessOnFirstAttempt() async throws {
        let client = CountedClient(results: [.success(makeOKResponse())])
        let retrying = RetryingNewsAPIClientDecorator(client: client, retryPolicy: RetryPolicy(maxRetries: 3, baseDelay: 0.01, maxDelay: 0.1, jitter: false))

        let result = try await retrying.request(TestResponse.self, endpoint: .sources)

        XCTAssertEqual(result.status, "ok")
        XCTAssertEqual(client.callCount, 1)
    }

    func testRetriesOnNetworkError() async throws {
        let client = CountedClient(results: [
            .failure(NewsAPIError.network),
            .failure(NewsAPIError.network),
            .success(makeOKResponse())
        ])
        let retrying = RetryingNewsAPIClientDecorator(client: client, retryPolicy: RetryPolicy(maxRetries: 3, baseDelay: 0.01, maxDelay: 0.1, jitter: false))

        let result = try await retrying.request(TestResponse.self, endpoint: .sources)

        XCTAssertEqual(result.status, "ok")
        XCTAssertEqual(client.callCount, 3)
    }

    func testThrowsAfterAllRetriesExhausted() async {
        let client = CountedClient(results: [
            .failure(NewsAPIError.network),
            .failure(NewsAPIError.network),
            .failure(NewsAPIError.network)
        ])
        let retrying = RetryingNewsAPIClientDecorator(client: client, retryPolicy: RetryPolicy(maxRetries: 3, baseDelay: 0.01, maxDelay: 0.1, jitter: false))

        do {
            _ = try await retrying.request(TestResponse.self, endpoint: .sources)
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(error as? NewsAPIError, .network)
            XCTAssertEqual(client.callCount, 3)
        }
    }

    func testDoesNotRetryOnCancelledError() async {
        let client = CountedClient(results: [
            .failure(NewsAPIError.cancelled)
        ])
        let retrying = RetryingNewsAPIClientDecorator(client: client, retryPolicy: RetryPolicy(maxRetries: 3, baseDelay: 0.01, maxDelay: 0.1, jitter: false))

        do {
            _ = try await retrying.request(TestResponse.self, endpoint: .sources)
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(error as? NewsAPIError, .cancelled)
            XCTAssertEqual(client.callCount, 1)
        }
    }

    func testDoesNotRetryOnDecodingError() async {
        let client = CountedClient(results: [
            .failure(NewsAPIError.decoding)
        ])
        let retrying = RetryingNewsAPIClientDecorator(client: client, retryPolicy: RetryPolicy(maxRetries: 3, baseDelay: 0.01, maxDelay: 0.1, jitter: false))

        do {
            _ = try await retrying.request(TestResponse.self, endpoint: .sources)
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(error as? NewsAPIError, .decoding)
            XCTAssertEqual(client.callCount, 1)
        }
    }

    func testDoesNotRetryOnMissingAPIKey() async {
        let client = CountedClient(results: [
            .failure(NewsAPIError.missingAPIKey)
        ])
        let retrying = RetryingNewsAPIClientDecorator(client: client, retryPolicy: RetryPolicy(maxRetries: 3, baseDelay: 0.01, maxDelay: 0.1, jitter: false))

        do {
            _ = try await retrying.request(TestResponse.self, endpoint: .sources)
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(error as? NewsAPIError, .missingAPIKey)
            XCTAssertEqual(client.callCount, 1)
        }
    }

    func testDoesNotRetryOnInvalidURL() async {
        let client = CountedClient(results: [
            .failure(NewsAPIError.invalidURL)
        ])
        let retrying = RetryingNewsAPIClientDecorator(client: client, retryPolicy: RetryPolicy(maxRetries: 3, baseDelay: 0.01, maxDelay: 0.1, jitter: false))

        do {
            _ = try await retrying.request(TestResponse.self, endpoint: .sources)
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(error as? NewsAPIError, .invalidURL)
            XCTAssertEqual(client.callCount, 1)
        }
    }

    func testRetriesOnInvalidResponse() async throws {
        let client = CountedClient(results: [
            .failure(NewsAPIError.invalidResponse),
            .success(makeOKResponse())
        ])
        let retrying = RetryingNewsAPIClientDecorator(client: client, retryPolicy: RetryPolicy(maxRetries: 3, baseDelay: 0.01, maxDelay: 0.1, jitter: false))

        let result = try await retrying.request(TestResponse.self, endpoint: .sources)

        XCTAssertEqual(result.status, "ok")
        XCTAssertEqual(client.callCount, 2)
    }

    func testRetriesOnEmptyResponse() async throws {
        let client = CountedClient(results: [
            .failure(NewsAPIError.emptyResponse),
            .success(makeOKResponse())
        ])
        let retrying = RetryingNewsAPIClientDecorator(client: client, retryPolicy: RetryPolicy(maxRetries: 3, baseDelay: 0.01, maxDelay: 0.1, jitter: false))

        let result = try await retrying.request(TestResponse.self, endpoint: .sources)

        XCTAssertEqual(result.status, "ok")
        XCTAssertEqual(client.callCount, 2)
    }

    func testRetriesOnServerError() async throws {
        let client = CountedClient(results: [
            .failure(NewsAPIError.apiStatus(code: "500", message: "Internal")),
            .success(makeOKResponse())
        ])
        let retrying = RetryingNewsAPIClientDecorator(client: client, retryPolicy: RetryPolicy(maxRetries: 3, baseDelay: 0.01, maxDelay: 0.1, jitter: false))

        let result = try await retrying.request(TestResponse.self, endpoint: .sources)

        XCTAssertEqual(result.status, "ok")
        XCTAssertEqual(client.callCount, 2)
    }

    func testRetriesOnRateLimit() async throws {
        let client = CountedClient(results: [
            .failure(NewsAPIError.apiStatus(code: "rateLimited", message: "Too many")),
            .success(makeOKResponse())
        ])
        let retrying = RetryingNewsAPIClientDecorator(client: client, retryPolicy: RetryPolicy(maxRetries: 3, baseDelay: 0.01, maxDelay: 0.1, jitter: false))

        let result = try await retrying.request(TestResponse.self, endpoint: .sources)

        XCTAssertEqual(result.status, "ok")
        XCTAssertEqual(client.callCount, 2)
    }

    func testDoesNotRetryOnClientError() async {
        let client = CountedClient(results: [
            .failure(NewsAPIError.apiStatus(code: "400", message: "Bad Request")),
            .success(makeOKResponse())
        ])
        let retrying = RetryingNewsAPIClientDecorator(client: client, retryPolicy: RetryPolicy(maxRetries: 3, baseDelay: 0.01, maxDelay: 0.1, jitter: false))

        do {
            _ = try await retrying.request(TestResponse.self, endpoint: .sources)
            XCTFail("Expected error")
        } catch {
            guard let newsError = error as? NewsAPIError else {
                XCTFail("Expected NewsAPIError, got \(error)")
                return
            }
            if case .apiStatus(let code, _) = newsError {
                XCTAssertEqual(code, "400")
            } else {
                XCTFail("Expected apiStatus, got \(newsError)")
            }
            XCTAssertEqual(client.callCount, 1)
        }
    }
}
