import Foundation

enum NewsAPIError: Error, Equatable {
    case invalidURL
    case missingAPIKey
    case network
    case invalidResponse
    case emptyResponse
    case decoding
    case apiStatus(code: String?, message: String?)
    case cancelled

    var userMessage: String {
        switch self {
        case .missingAPIKey:
            return L10n.text("error.missingApiKey")

        case .network:
            return L10n.text("error.network")

        case .invalidURL, .invalidResponse, .emptyResponse, .decoding, .apiStatus:
            return L10n.text("error.generic")

        case .cancelled:
            return ""
        }
    }

    var debugDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid NewsAPI URL."

        case .missingAPIKey:
            return "Missing NewsAPI key."

        case .network:
            return "Network request failed."

        case .invalidResponse:
            return "Invalid HTTP response."

        case .emptyResponse:
            return "NewsAPI returned an empty response."

        case .decoding:
            return "NewsAPI response decoding failed."

        case let .apiStatus(code, message):
            return "NewsAPI status error: \(code ?? "unknown") \(message ?? "")"

        case .cancelled:
            return "Request cancelled."
        }
    }
}
