import Combine
import UIKit

enum DeepLink: Equatable {
    case article(id: String)
    case source(id: String)
    case search(query: String)
    case readingList

    init?(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host?.lowercased() else { return nil }

        let pathComponents = components.path.split(separator: "/").map(String.init)
        let queryItems = components.queryItems ?? []

        switch host {
        case "article":
            guard let id = pathComponents.first, !id.isEmpty else { return nil }
            self = .article(id: id)
        case "source":
            guard let id = pathComponents.first, !id.isEmpty else { return nil }
            self = .source(id: id)
        case "search":
            let query = queryItems.first(where: { $0.name == "q" })?.value ?? pathComponents.first
            guard let query, !query.isEmpty else { return nil }
            self = .search(query: query)
        case "readinglist", "reading-list":
            self = .readingList
        default:
            return nil
        }
    }
}

final class DeepLinkHandler {
    static let shared = DeepLinkHandler()

    @Published private(set) var pendingDeepLink: DeepLink?

    func handle(_ url: URL) -> Bool {
        guard let deepLink = DeepLink(url: url) else { return false }
        pendingDeepLink = deepLink
        return true
    }

    func consume() -> DeepLink? {
        let link = pendingDeepLink
        pendingDeepLink = nil
        return link
    }
}
