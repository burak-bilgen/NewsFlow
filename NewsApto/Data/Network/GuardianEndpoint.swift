import Foundation

enum GuardianEndpoint {
    case search(query: String?, page: Int, pageSize: Int, section: String?)

    var path: String {
        switch self {
        case .search: return "/search"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case let .search(query, page, pageSize, section):
            var items: [URLQueryItem] = [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "page-size", value: String(pageSize)),
                URLQueryItem(name: "show-fields", value: "thumbnail,trailText,bodyText"),
                URLQueryItem(name: "show-blocks", value: "main"),
            ]
            if let query, !query.isEmpty {
                items.append(URLQueryItem(name: "q", value: query))
            }
            if let section, !section.isEmpty {
                items.append(URLQueryItem(name: "section", value: section))
            }
            return items
        }
    }
}
