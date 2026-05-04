import Foundation

enum NewsAPIEndpoint: Equatable {
    case sources
    case topHeadlines(sourceID: String)

    var path: String {
        switch self {
        case .sources:
            return "/v2/sources"
        case .topHeadlines:
            return "/v2/top-headlines"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .sources:
            return []
        case let .topHeadlines(sourceID):
            return [URLQueryItem(name: "sources", value: sourceID)]
        }
    }
}
