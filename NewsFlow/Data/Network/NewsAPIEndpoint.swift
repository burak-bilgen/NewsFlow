import Foundation

enum NewsAPIEndpoint: Equatable {
    case sources
    case topHeadlines(sourceID: String, page: Int, pageSize: Int)

    var path: String {
        switch self {
        case .sources:
            return "/v2/top-headlines/sources"

        case .topHeadlines:
            return "/v2/top-headlines"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .sources:
            return [
                URLQueryItem(name: "language", value: "en")
            ]

        case let .topHeadlines(sourceID, page, pageSize):
            return [
                URLQueryItem(name: "sources", value: sourceID),
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "pageSize", value: String(pageSize))
            ]
        }
    }
}
