import Foundation

enum NewsAPIEndpoint: Equatable {
    case topHeadlines(sourceID: String, page: Int, pageSize: Int)

    var path: String {
        switch self {
        case .topHeadlines:
            return "/v2/top-headlines"
        }
    }

    private static let validCategories: Set<String> = [
        "general", "business", "entertainment", "health", "science", "sports", "technology"
    ]

    var queryItems: [URLQueryItem] {
        switch self {
        case let .topHeadlines(sourceID, page, pageSize):
            var items: [URLQueryItem] = [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "pageSize", value: String(pageSize))
            ]
            if sourceID == "all" {
                items.append(URLQueryItem(name: "country", value: "us"))
            } else if Self.validCategories.contains(sourceID) {
                items.append(URLQueryItem(name: "country", value: "us"))
                items.append(URLQueryItem(name: "category", value: sourceID))
            } else {
                items.append(URLQueryItem(name: "sources", value: sourceID))
            }
            return items
        }
    }
}
