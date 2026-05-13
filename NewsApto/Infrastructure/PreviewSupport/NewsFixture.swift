import Foundation

#if DEBUG
enum NewsFixture {
    static let articlesBySource: [String: [Article]] = [
        "bbc-news": articles(sourceID: "bbc-news"),
        "techcrunch": articles(sourceID: "techcrunch")
    ]

    private static func articles(sourceID: String) -> [Article] {
        let imageURLs = [
            "https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=800",
            "https://images.unsplash.com/photo-1495020689067-958852a7765e?w=800",
            "https://images.unsplash.com/photo-1585829365295-ab7cd400c167?w=800",
            "https://images.unsplash.com/photo-1523995462485-3d171b5c8fa9?w=800",
            "https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=800",
            "https://images.unsplash.com/photo-1486312338219-ce68d2c6f44d?w=800"
        ]
        let titles = [
            "Global markets open higher after major policy update shakes Wall Street",
            "Technology leaders prepare groundbreaking new safety standards for AI systems",
            "Major cities invest billions in cleaner public transport infrastructure",
            "Researchers publish startling new climate findings ahead of global summit",
            "Space exploration enters new era with breakthrough propulsion technology",
            "Healthcare revolution: New treatment shows 95% efficacy in latest trials"
        ]
        return titles.enumerated().map { index, title in
            Article(
                id: "\(sourceID)-\(index)",
                sourceID: sourceID,
                title: title,
                imageURL: URL(string: imageURLs[index % imageURLs.count]),
                publishedAt: Date(timeIntervalSinceNow: -Double(index * 3_600)),
                url: URL(string: "https://example.com/\(sourceID)/\(index)")
            )
        }
    }
}
#endif
