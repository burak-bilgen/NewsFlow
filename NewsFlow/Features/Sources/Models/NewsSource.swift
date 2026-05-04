import Foundation

/// Represents a news source (e.g. BBC News, TechCrunch).
/// The `url` field holds the source's website URL, used to fetch
/// the logo via Clearbit's free Logo API.
struct NewsSource: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let description: String
    let category: String
    let language: String
    let url: String?

    /// Extracts the domain from the source URL for Clearbit logo lookup.
    /// Example: "https://www.bbc.co.uk" → "bbc.co.uk"
    var logoURL: URL? {
        guard let url else { return nil }
        if let host = URL(string: url)?.host {
            return URL(string: "https://logo.clearbit.com/\(host)")
        }
        return nil
    }

    /// Returns up to 2 uppercase initials from the source name.
    /// Example: "BBC News" → "BN", "The Verge" → "TV"
    var nameInitials: String {
        let words = name.split(separator: " ")
        let initials = words.prefix(2).compactMap { $0.first?.uppercased() }
        return initials.joined()
    }
}
