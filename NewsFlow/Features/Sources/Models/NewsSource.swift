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
        // Clearbit Logo API: https://logo.clearbit.com/{domain}
        if let host = URL(string: url)?.host {
            return URL(string: "https://logo.clearbit.com/\(host)")
        }
        return nil
    }
}
