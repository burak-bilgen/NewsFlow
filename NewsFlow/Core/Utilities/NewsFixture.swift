import Foundation

#if DEBUG
enum NewsFixture {
    static let sources = [
        NewsSource(
            id: "bbc-news",
            name: "BBC News",
            description: "Use BBC News for up-to-the-minute news, breaking news, video, audio and feature stories.",
            category: "general",
            language: "en"
        ),
        NewsSource(
            id: "techcrunch",
            name: "TechCrunch",
            description: "The latest technology news and information on startups.",
            category: "technology",
            language: "en"
        ),
        NewsSource(
            id: "le-monde",
            name: "Le Monde",
            description: "French and international news.",
            category: "general",
            language: "fr"
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
            articlesRepository: repo,
            readingListRepository: readingList,
            errorSimulator: nil
        )
    }
}

final class MockSourcesRepository: SourcesRepositoryProtocol {
    private let sources: [NewsSource]

    init(sources: [NewsSource]) {
        self.sources = sources
    }

    func fetchSources() async throws -> [NewsSource] {
        sources
    }
}

final class MockArticlesRepository: ArticlesRepositoryProtocol {
    private let articlesBySource: [String: [Article]]

    init(articlesBySource: [String: [Article]]) {
        self.articlesBySource = articlesBySource
    }

    func fetchArticles(sourceID: String) async throws -> [Article] {
        articlesBySource[sourceID] ?? []
    }
}

actor InMemoryReadingListRepository: ReadingListRepositoryProtocol {
    private var articles: [String: Article] = [:]

    func savedArticleIDs() async -> Set<String> {
        Set(articles.keys)
    }

    func isSaved(articleID: String) async -> Bool {
        articles[articleID] != nil
    }

    func add(_ article: Article) async throws {
        articles[article.id] = article
    }

    func remove(articleID: String) async throws {
        articles[articleID] = nil
    }
}
#endif
