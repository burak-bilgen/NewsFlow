import Foundation

protocol NewsAPIRequestBuilding {
    func makeRequest(endpoint: NewsAPIEndpoint) throws -> URLRequest
}

struct NewsAPIRequestBuilder: NewsAPIRequestBuilding {
    private let baseURLProvider: () -> URL?
    private let apiKeyProvider: () -> String?
    private let timeoutInterval: TimeInterval

    init(
        baseURLProvider: @escaping () -> URL? = { APIConfig.baseURL },
        apiKeyProvider: @escaping () -> String? = { APIConfig.apiKey },
        timeoutInterval: TimeInterval = 15
    ) {
        self.baseURLProvider = baseURLProvider
        self.apiKeyProvider = apiKeyProvider
        self.timeoutInterval = timeoutInterval
    }

    func makeRequest(endpoint: NewsAPIEndpoint) throws -> URLRequest {
        guard let apiKey = apiKeyProvider(), !apiKey.isEmpty else {
            throw NewsAPIError.missingAPIKey
        }

        guard let baseURL = baseURLProvider() else {
            throw NewsAPIError.invalidURL
        }

        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: false
        ) else {
            throw NewsAPIError.invalidURL
        }

        var queryItems = endpoint.queryItems
        queryItems.append(URLQueryItem(name: "apiKey", value: apiKey))
        components.queryItems = queryItems

        guard let url = components.url else {
            throw NewsAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = timeoutInterval
        return request
    }
}
