import Foundation

actor AggregateArticlesRepository: ArticlesRepositoryProtocol {
    private let newsAPIRepository: ArticlesRepositoryProtocol
    private let guardianClient: GuardianClientProtocol
    private let nytClient: NYTClientProtocol

    init(
        newsAPIRepository: ArticlesRepositoryProtocol,
        guardianClient: GuardianClientProtocol,
        nytClient: NYTClientProtocol
    ) {
        self.newsAPIRepository = newsAPIRepository
        self.guardianClient = guardianClient
        self.nytClient = nytClient
    }

    func fetchArticles(sourceID: String, page: Int, pageSize: Int) async throws -> PaginatedResult<Article> {
        async let newsAPIFuture = try? newsAPIRepository.fetchArticles(sourceID: sourceID, page: page, pageSize: pageSize)
        async let guardianFuture = try? guardianClient.search(query: nil, page: page, pageSize: pageSize, section: sourceID == "all" ? nil : sourceID)
        async let nytFuture = try? nytClient.search(query: nil, page: page, section: sourceID == "all" ? nil : sourceID)

        let (newsAPIResult, guardianResult, nytResult) = await (newsAPIFuture, guardianFuture, nytFuture)

        logSourceErrors(newsAPI: newsAPIResult, guardian: guardianResult, nyt: nytResult)

        return merge(
            newsAPIPaginated: newsAPIResult,
            guardianArticles: guardianResult,
            nytResult: nytResult,
            page: page,
            pageSize: pageSize
        )
    }

    func fetchAllArticles(page: Int, pageSize: Int) async throws -> PaginatedResult<Article> {
        async let newsAPIFuture = try? newsAPIRepository.fetchArticles(sourceID: "all", page: page, pageSize: pageSize)
        async let guardianFuture = try? guardianClient.search(query: nil, page: page, pageSize: pageSize * 2, section: nil)
        async let nytFuture = try? nytClient.search(query: nil, page: page, section: nil)

        let (newsAPIResult, guardianResult, nytResult) = await (newsAPIFuture, guardianFuture, nytFuture)

        logSourceErrors(newsAPI: newsAPIResult, guardian: guardianResult, nyt: nytResult)

        return merge(
            newsAPIPaginated: newsAPIResult,
            guardianArticles: guardianResult,
            nytResult: nytResult,
            page: page,
            pageSize: pageSize
        )
    }
}

extension AggregateArticlesRepository: CacheBypassing {
    func fetchArticlesBypassingCache(sourceID: String, page: Int, pageSize: Int) async throws -> PaginatedResult<Article> {
        async let newsAPIFuture: PaginatedResult<Article>? = {
            if let cacheBypassingRepo = newsAPIRepository as? CacheBypassing {
                return try? await cacheBypassingRepo.fetchArticlesBypassingCache(
                    sourceID: sourceID,
                    page: page,
                    pageSize: pageSize
                )
            }
            return try? await newsAPIRepository.fetchArticles(sourceID: sourceID, page: page, pageSize: pageSize)
        }()
        async let guardianFuture = try? guardianClient.search(query: nil, page: page, pageSize: pageSize, section: sourceID == "all" ? nil : sourceID)
        async let nytFuture = try? nytClient.search(query: nil, page: page, section: sourceID == "all" ? nil : sourceID)

        let (newsAPIResult, guardianResult, nytResult) = await (newsAPIFuture, guardianFuture, nytFuture)

        logSourceErrors(newsAPI: newsAPIResult, guardian: guardianResult, nyt: nytResult)

        return merge(
            newsAPIPaginated: newsAPIResult,
            guardianArticles: guardianResult,
            nytResult: nytResult,
            page: page,
            pageSize: pageSize
        )
    }
}

extension AggregateArticlesRepository: ArticleSearchProtocol {
    func searchArticles(query: String, page: Int, pageSize: Int) async throws -> PaginatedResult<Article> {
        async let newsAPIFuture = try? newsAPIRepository.fetchArticles(sourceID: "all", page: page, pageSize: pageSize)
        async let guardianFuture = try? guardianClient.search(query: query, page: page, pageSize: pageSize, section: nil)
        async let nytFuture = try? nytClient.search(query: query, page: page, section: nil)

        let (newsAPIResult, guardianResult, nytResult) = await (newsAPIFuture, guardianFuture, nytFuture)

        logSourceErrors(newsAPI: newsAPIResult, guardian: guardianResult, nyt: nytResult)

        return merge(
            newsAPIPaginated: newsAPIResult,
            guardianArticles: guardianResult,
            nytResult: nytResult,
            page: page,
            pageSize: pageSize
        )
    }
}

extension AggregateArticlesRepository: CategoryFilterProtocol {
    func fetchArticlesByCategory(_ category: String, page: Int, pageSize: Int) async throws -> PaginatedResult<Article> {
        async let newsAPIFuture = try? newsAPIRepository.fetchArticles(sourceID: category, page: page, pageSize: pageSize)
        async let guardianFuture = try? guardianClient.search(query: nil, page: page, pageSize: pageSize, section: category)
        async let nytFuture = try? nytClient.search(query: nil, page: page, section: category)

        let (newsAPIResult, guardianResult, nytResult) = await (newsAPIFuture, guardianFuture, nytFuture)

        logSourceErrors(newsAPI: newsAPIResult, guardian: guardianResult, nyt: nytResult)

        return merge(
            newsAPIPaginated: newsAPIResult,
            guardianArticles: guardianResult,
            nytResult: nytResult,
            page: page,
            pageSize: pageSize
        )
    }
}

private extension AggregateArticlesRepository {
    func logSourceErrors(newsAPI: PaginatedResult<Article>?, guardian: [Article]?, nyt: NYTSearchResult?) {
        if newsAPI == nil { NewsAptoLogger.shared.warning("NewsAPI source unavailable", category: "Repository") }
        if guardian == nil { NewsAptoLogger.shared.warning("Guardian source unavailable", category: "Repository") }
        if nyt == nil { NewsAptoLogger.shared.warning("NYT source unavailable", category: "Repository") }
    }

    func merge(
        newsAPIPaginated: PaginatedResult<Article>?,
        guardianArticles: [Article]?,
        nytResult: NYTSearchResult?,
        page: Int,
        pageSize: Int
    ) -> PaginatedResult<Article> {
        var allArticles: [Article] = []
        var hasMore = false

        if let paginated = newsAPIPaginated {
            allArticles.append(contentsOf: paginated.items)
            if paginated.hasMorePages { hasMore = true }
        }

        if let articles = guardianArticles {
            allArticles.append(contentsOf: articles)
            if articles.count >= pageSize { hasMore = true }
        }

        if let result = nytResult {
            allArticles.append(contentsOf: result.articles)
            if result.hasMore { hasMore = true }
        }

        if allArticles.isEmpty {
            allArticles = Self.offlineFallback
            NewsAptoLogger.shared.warning("All APIs unavailable — showing offline content", category: "Repository")
        }

        allArticles = deduplicated(allArticles)
        allArticles.sort { ($0.publishedAt ?? .distantPast) > ($1.publishedAt ?? .distantPast) }

        return PaginatedResult(
            items: allArticles,
            currentPage: page,
            hasMorePages: hasMore
        )
    }

    private static let offlineFallback: [Article] = {
        let now = Date()
        return [
            Article(id: "offline-1", sourceID: "bbc-news", title: "Global Markets Rally as Tech Sector Surges", description: "Stock markets worldwide reached new heights today as technology companies reported record-breaking quarterly earnings, driven by strong demand in AI and cloud computing sectors.", imageURL: URL(string: "https://images.unsplash.com/photo-1611532736597-de2d4265fba3?w=600"), publishedAt: now.addingTimeInterval(-1800), url: URL(string: "https://example.com/markets-rally"), sourceName: "BBC News"),
            Article(id: "offline-2", sourceID: "bbc-news", title: "Breakthrough Study Reveals New Insights into Brain Health", description: "Neuroscientists have published groundbreaking research showing that specific dietary patterns can significantly reduce the risk of cognitive decline in aging populations.", imageURL: URL(string: "https://images.unsplash.com/photo-1559757175-5700dde675bc?w=600"), publishedAt: now.addingTimeInterval(-3600), url: URL(string: "https://example.com/brain-health"), sourceName: "The Guardian"),
            Article(id: "offline-3", sourceID: "bbc-news", title: "Space Agency Announces New Lunar Mission Timeline", description: "The ambitious new lunar exploration program aims to establish a permanent research outpost on the Moon's south pole by the end of the decade, marking a new chapter in space exploration.", imageURL: URL(string: "https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?w=600"), publishedAt: now.addingTimeInterval(-5400), url: URL(string: "https://example.com/lunar-mission"), sourceName: "BBC News"),
            Article(id: "offline-4", sourceID: "bbc-news", title: "Revolutionary Clean Energy Project Powers Million Homes", description: "The world's largest offshore wind farm has officially begun operations, providing clean electricity to over one million households and significantly reducing carbon emissions.", imageURL: URL(string: "https://images.unsplash.com/photo-1466611653912-2d6c7e2d0c5e?w=600"), publishedAt: now.addingTimeInterval(-7200), url: URL(string: "https://example.com/clean-energy"), sourceName: "TechCrunch"),
            Article(id: "offline-5", sourceID: "bbc-news", title: "Major Infrastructure Bill Passes: What It Means", description: "The landmark infrastructure legislation includes unprecedented investments in sustainable transportation, broadband access, and renewable energy systems nationwide.", imageURL: URL(string: "https://images.unsplash.com/photo-1541888946425-d81bb6a2eabc?w=600"), publishedAt: now.addingTimeInterval(-9000), url: URL(string: "https://example.com/infrastructure-bill"), sourceName: "The New York Times"),
            Article(id: "offline-6", sourceID: "bbc-news", title: "New App Redefines Mobile News Consumption", description: "A revolutionary approach to news delivery combines AI-powered curation with beautiful design, giving readers a personalized and immersive experience.", imageURL: URL(string: "https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=600"), publishedAt: now.addingTimeInterval(-10800), url: URL(string: "https://example.com/news-app"), sourceName: "TechCrunch"),
            Article(id: "offline-7", sourceID: "bbc-news", title: "Olympic Committee Announces Groundbreaking Format Changes", description: "The upcoming games will feature several new sports and a revamped competition format designed to attract younger audiences and enhance the spectator experience.", imageURL: URL(string: "https://images.unsplash.com/photo-1461896836934-bd45ba8fcf9b?w=600"), publishedAt: now.addingTimeInterval(-12600), url: URL(string: "https://example.com/olympic-changes"), sourceName: "BBC News"),
            Article(id: "offline-8", sourceID: "bbc-news", title: "Healthcare AI System Achieves Breakthrough Accuracy", description: "A new artificial intelligence system has demonstrated remarkable accuracy in early disease detection, potentially revolutionizing preventive medicine and reducing healthcare costs.", imageURL: URL(string: "https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=600"), publishedAt: now.addingTimeInterval(-14400), url: URL(string: "https://example.com/healthcare-ai"), sourceName: "The Guardian"),
        ]
    }()

    func deduplicated(_ articles: [Article]) -> [Article] {
        var seen: Set<String> = []
        var unique: [Article] = []

        for article in articles {
            let key = dedupeKey(for: article)
            guard seen.insert(key).inserted else { continue }
            unique.append(article)
        }

        return unique
    }

    func dedupeKey(for article: Article) -> String {
        if let url = article.url?.absoluteString.lowercased(), !url.isEmpty {
            return "url:\(url)"
        }

        let normalizedTitle = article.title
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        if !normalizedTitle.isEmpty {
            return "title:\(normalizedTitle)"
        }

        return "id:\(article.id)"
    }
}
