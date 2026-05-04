import Foundation

// MARK: - Article Sorting Protocol

protocol ArticleSorting {
    func newestFirst(_ articles: [Article]) -> [Article]
}

// MARK: - Article Sorter Implementation

struct ArticleSorter: ArticleSorting {
    func newestFirst(_ articles: [Article]) -> [Article] {
        articles.sorted { lhs, rhs in
            switch (lhs.publishedAt, rhs.publishedAt) {
            case let (left?, right?):
                return left > right

            case (_?, nil):
                return true

            case (nil, _?):
                return false

            case (nil, nil):
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
        }
    }
}
