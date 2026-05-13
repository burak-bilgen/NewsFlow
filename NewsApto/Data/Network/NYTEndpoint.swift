import Foundation

enum NYTEndpoint {
    case search(query: String?, page: Int, section: String?)

    var path: String {
        switch self {
        case .search: return "/articlesearch.json"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case let .search(query, page, section):
            var items: [URLQueryItem] = [
                URLQueryItem(name: "page", value: String(max(0, page - 1))),
            ]
            if let query, !query.isEmpty {
                items.append(URLQueryItem(name: "q", value: query))
            }
            if let section, !section.isEmpty {
                items.append(URLQueryItem(name: "fq", value: "section_name:\"\(section)\""))
            }
            return items
        }
    }
}
