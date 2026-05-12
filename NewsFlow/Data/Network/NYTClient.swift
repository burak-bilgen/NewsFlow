import Foundation

protocol NYTClientProtocol {
    func search(query: String?, page: Int, section: String?) async throws -> [Article]
}

final class NYTClient: NYTClientProtocol {
    private let session: URLSessionProtocol
    private let config: APIConfig.NYTConfig
    private let decoder: JSONDecoder

    init(
        session: URLSessionProtocol = URLSession.shared,
        config: APIConfig.NYTConfig = APIConfig.nyt,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.session = session
        self.config = config
        self.decoder = decoder
    }

    func search(query: String?, page: Int, section: String?) async throws -> [Article] {
        guard let baseURL = config.baseURL else { throw NewsAPIError.invalidURL }
        guard let apiKey = config.apiKey, !apiKey.isEmpty else { throw NewsAPIError.missingAPIKey }

        let endpoint = NYTEndpoint.search(query: query, page: page, section: section)
        guard var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false) else {
            throw NewsAPIError.invalidURL
        }

        var items = endpoint.queryItems
        items.append(URLQueryItem(name: "api-key", value: apiKey))
        components.queryItems = items

        guard let url = components.url else {
            NewsFlowLogger.shared.error("Invalid NYT URL", category: "Network")
            throw NewsAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15

        do {
            let (data, response) = try await session.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                NewsFlowLogger.shared.debug("NYT API status \(httpResponse.statusCode)", category: "Network")
            }

            let decoded = try decoder.decode(NYTSearchResponse.self, from: data)

            if let fault = decoded.fault {
                throw NewsAPIError.apiStatus(code: nil, message: fault.faultstring)
            }

            return decoded.response?.docs?.map { $0.domainModel() } ?? []
        } catch let error as NewsAPIError {
            NewsFlowLogger.shared.error("NYT API error: \(error.debugDescription)", category: "Network")
            throw error
        } catch {
            NewsFlowLogger.shared.error("NYT request failed: \(error.localizedDescription)", category: "Network")
            throw error
        }
    }
}
