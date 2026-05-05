import Foundation

actor NetworkRequestFailureCounter {
    private var requestCount = 0
    private let failingInterval: Int

    init(failingInterval: Int = 3) {
        self.failingInterval = max(failingInterval, 1)
    }

    func shouldFailNextRequest() -> Bool {
        requestCount += 1
        return requestCount.isMultiple(of: failingInterval)
    }

    func reset() {
        requestCount = 0
    }
}

/// Decorates a concrete NewsAPI client with deterministic failure simulation.
/// The production client remains unaware of counters, assessment-only failure
/// cadence, or UI retry behavior.
final class SimulatedNetworkErrorClientDecorator: NewsAPIClientProtocol {
    private let client: NewsAPIClientProtocol
    private let failureCounter: NetworkRequestFailureCounter

    init(
        client: NewsAPIClientProtocol,
        failureCounter: NetworkRequestFailureCounter = NetworkRequestFailureCounter()
    ) {
        self.client = client
        self.failureCounter = failureCounter
    }

    func request<Response: NewsAPIResponseEnvelope>(
        _ responseType: Response.Type,
        endpoint: NewsAPIEndpoint
    ) async throws -> Response {
        if await failureCounter.shouldFailNextRequest() {
            throw NewsAPIError.simulatedNetwork
        }
        return try await client.request(responseType, endpoint: endpoint)
    }
}
