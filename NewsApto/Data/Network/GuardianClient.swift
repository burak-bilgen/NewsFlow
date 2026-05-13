import Foundation

protocol GuardianClientProtocol {
    func search(query: String?, page: Int, pageSize: Int, section: String?) async throws -> [Article]
}

final class GuardianClient: GuardianClientProtocol {
    private let session: URLSessionProtocol
    private let config: APIConfig.GuardianConfig
    private let decoder: JSONDecoder

    init(
        session: URLSessionProtocol = URLSession.shared,
        config: APIConfig.GuardianConfig = APIConfig.guardian,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.session = session
        self.config = config
        self.decoder = decoder
    }

    func search(query: String?, page: Int, pageSize: Int, section: String?) async throws -> [Article] {
        guard let baseURL = config.baseURL else { throw NewsAPIError.invalidURL }
        guard let apiKey = config.apiKey, !apiKey.isEmpty else { throw NewsAPIError.missingAPIKey }

        let endpoint = GuardianEndpoint.search(query: query, page: page, pageSize: pageSize, section: section)
        guard var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false) else {
            throw NewsAPIError.invalidURL
        }

        var items = endpoint.queryItems
        items.append(URLQueryItem(name: "api-key", value: apiKey))
        components.queryItems = items

        guard let url = components.url else {
            NewsAptoLogger.shared.error("Invalid Guardian URL", category: "Network")
            throw NewsAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15

        do {
            let (data, response) = try await session.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                NewsAptoLogger.shared.debug("Guardian API status \(httpResponse.statusCode)", category: "Network")
            }

            let decoded = try decoder.decode(GuardianSearchResponse.self, from: data)
            guard decoded.response.status == "ok" else {
                throw NewsAPIError.apiStatus(code: nil, message: "Guardian API error")
            }

            return decoded.response.results.map { $0.domainModel() }
        } catch let error as NewsAPIError {
            NewsAptoLogger.shared.error("Guardian API error: \(error.debugDescription)", category: "Network")
            throw error
        } catch {
            NewsAptoLogger.shared.error("Guardian request failed: \(error.localizedDescription)", category: "Network")
            throw error
        }
    }
}
