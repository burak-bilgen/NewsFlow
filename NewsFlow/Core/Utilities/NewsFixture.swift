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
        [
            Article(
                id: "\(sourceID)-1",
                sourceID: sourceID,
                title: "Global markets open higher after policy update",
                imageURL: nil,
                publishedAt: Date(timeIntervalSince1970: 1_800_000_000),
                url: URL(string: "https://example.com/\(sourceID)/1")
            ),
            Article(
                id: "\(sourceID)-2",
                sourceID: sourceID,
                title: "Technology leaders prepare new safety standards",
                imageURL: nil,
                publishedAt: Date(timeIntervalSince1970: 1_799_999_000),
                url: URL(string: "https://example.com/\(sourceID)/2")
            ),
            Article(
                id: "\(sourceID)-3",
                sourceID: sourceID,
                title: "Cities invest in cleaner public transport",
                imageURL: nil,
                publishedAt: Date(timeIntervalSince1970: 1_799_998_000),
                url: URL(string: "https://example.com/\(sourceID)/3")
            ),
            Article(
                id: "\(sourceID)-4",
                sourceID: sourceID,
                title: "Researchers publish new climate findings",
                imageURL: nil,
                publishedAt: Date(timeIntervalSince1970: 1_799_997_000),
                url: URL(string: "https://example.com/\(sourceID)/4")
            )
        ]
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
