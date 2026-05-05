import Foundation

#if DEBUG
enum NewsFixture {
    static let sources = [
        NewsSource(
            id: "bbc-news",
            name: "BBC News",
            description: "Use BBC News for up-to-the-minute news, breaking news, video, audio and feature stories.",
            category: "general",
            language: "en",
            url: "https://www.bbc.co.uk/news"
        ),
        NewsSource(
            id: "techcrunch",
            name: "TechCrunch",
            description: "The latest technology news and information on startups.",
            category: "technology",
            language: "en",
            url: "https://techcrunch.com"
        ),
        NewsSource(
            id: "reuters",
            name: "Reuters",
            description: "Reuters.com brings you the latest news from around the world.",
            category: "general",
            language: "en",
            url: "https://www.reuters.com"
        ),
        NewsSource(
            id: "the-verge",
            name: "The Verge",
            description: "The Verge covers the intersection of technology, science, art, and culture.",
            category: "technology",
            language: "en",
            url: "https://www.theverge.com"
        ),
        NewsSource(
            id: "espn",
            name: "ESPN",
            description: "ESPN has up-to-the-minute sports news coverage, scores, highlights and commentary.",
            category: "sports",
            language: "en",
            url: "https://www.espn.com"
        ),
        NewsSource(
            id: "bloomberg",
            name: "Bloomberg",
            description: "Bloomberg delivers business and markets news, data, analysis, and video.",
            category: "business",
            language: "en",
            url: "https://www.bloomberg.com"
        ),
        NewsSource(
            id: "national-geographic",
            name: "National Geographic",
            description: "Reporting our world daily: original nature and science news.",
            category: "science",
            language: "en",
            url: "https://www.nationalgeographic.com"
        ),
        NewsSource(
            id: "entertainment-weekly",
            name: "Entertainment Weekly",
            description: "Entertainment Weekly has all the latest news about TV shows, movies, and music.",
            category: "entertainment",
            language: "en",
            url: "https://ew.com"
        )
    ]

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

    @MainActor
    static func previewViewModel(sourceID: String = "bbc-news") -> ArticlesViewModel {
        let source = sources.first { $0.id == sourceID } ?? sources[0]
        let repo = MockArticlesRepository(articlesBySource: articlesBySource)
        let readingList = InMemoryReadingListRepository()
        return ArticlesViewModel(
            source: source,
            fetchUseCase: FetchArticlesUseCase(repository: repo),
            readingListUseCase: ManageReadingListUseCase(repository: readingList)
        )
    }
}
#endif
