import Foundation


struct RetryPolicy {
    let maxRetries: Int
    let baseDelay: TimeInterval
    let maxDelay: TimeInterval
    let jitter: Bool

    init(
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 30.0,
        jitter: Bool = true
    ) {
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.jitter = jitter
    }

    func delay(forAttempt attempt: Int) -> TimeInterval {
        let exponential = baseDelay * pow(2.0, Double(attempt))
        let clamped = min(exponential, maxDelay)
        guard jitter else { return clamped }
        let jitterAmount = Double.random(in: 0...0.3) * clamped
        return clamped + jitterAmount
    }
}


final class RetryingNewsAPIClientDecorator: NewsAPIClientProtocol {
    private let client: NewsAPIClientProtocol
    private let retryPolicy: RetryPolicy

    init(client: NewsAPIClientProtocol, retryPolicy: RetryPolicy = RetryPolicy()) {
        self.client = client
        self.retryPolicy = retryPolicy
    }

    func request<Response: NewsAPIResponseEnvelope>(
        _ responseType: Response.Type,
        endpoint: NewsAPIEndpoint
    ) async throws -> Response {
        var lastError: Error?

        for attempt in 0..<retryPolicy.maxRetries {
            do {
                return try await client.request(responseType, endpoint: endpoint)
            } catch let error as NewsAPIError {
                lastError = error
                guard shouldRetry(error), attempt < retryPolicy.maxRetries - 1 else {
                    throw error
                }
                let delay = retryPolicy.delay(forAttempt: attempt)
                let delayStr = String(format: "%.1f", delay)
                let attemptStr = "\(attempt + 1)/\(retryPolicy.maxRetries)"
                NewsAptoLogger.shared.warning(
                    "Request failed with \(error). Retrying in \(delayStr)s (attempt \(attemptStr))",
                    category: "Network"
                )
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            } catch {
                lastError = error
                throw error
            }
        }

        throw lastError ?? NewsAPIError.network
    }


    private func shouldRetry(_ error: NewsAPIError) -> Bool {
        switch error {
        case .network, .invalidResponse, .emptyResponse:
            return true
        case .apiStatus(let code, _):
            if let code = code, code.hasPrefix("5") || code == "rateLimited" {
                return true
            }
            return false
        case .cancelled, .missingAPIKey, .invalidURL, .decoding:
            return false
        }
    }
}
