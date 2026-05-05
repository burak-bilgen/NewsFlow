import Foundation

struct Article: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    let sourceID: String
    let title: String
    let imageURL: URL?
    let publishedAt: Date?
    let url: URL?

    var displayDate: String {
        ArticleDateFormatter.displayString(from: publishedAt)
    }
}
