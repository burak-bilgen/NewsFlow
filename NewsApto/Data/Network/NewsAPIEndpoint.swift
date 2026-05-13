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
            var items: [URLQueryItem] = [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "pageSize", value: String(pageSize))
            ]
            if sourceID == "all" {
                items.append(URLQueryItem(name: "country", value: "us"))
            } else {
                items.append(URLQueryItem(name: "sources", value: sourceID))
            }
            return items
        }
    }
}
