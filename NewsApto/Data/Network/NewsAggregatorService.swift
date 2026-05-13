import Foundation

// MARK: - Aggregated Result

struct AggregatedResult: Sendable {
    let articles: [Article]
    let sourceCount: Int
}

// MARK: - News Aggregating Protocol

protocol NewsAggregating: Sendable {
    func fetchFeed(page: Int, pageSize: Int) async -> AggregatedResult
}

// MARK: - News Aggregator Service

actor NewsAggregatorService: NewsAggregating {
    private let newsAPIRepository: ArticlesRepositoryProtocol
    private let guardianClient: GuardianClientProtocol
    private let nytClient: NYTClientProtocol
    private let gnewsClient: GNewsClient
    private let newsDataClient: NewsDataClient
    private let hackerNewsClient: HackerNewsClient
    private let enhancedScorer: EnhancedArticleScorer
    private let topicDiversity: TopicDiversityEngine
    private let behaviorTracker: UserBehaviorTracker
    private var inflightFeed: Task<AggregatedResult, Never>?

    init(
        newsAPIRepository: ArticlesRepositoryProtocol,
        guardianClient: GuardianClientProtocol,
        nytClient: NYTClientProtocol,
        gnewsClient: GNewsClient = GNewsClient(),
        newsDataClient: NewsDataClient = NewsDataClient(),
        hackerNewsClient: HackerNewsClient = HackerNewsClient()
    ) {
        self.newsAPIRepository = newsAPIRepository
        self.guardianClient = guardianClient
        self.nytClient = nytClient
        self.gnewsClient = gnewsClient
        self.newsDataClient = newsDataClient
        self.hackerNewsClient = hackerNewsClient
        self.enhancedScorer = EnhancedArticleScorer()
        self.topicDiversity = TopicDiversityEngine()
        self.behaviorTracker = UserBehaviorTracker.shared
    }

    func fetchFeed(page: Int = 1, pageSize: Int = 30) async -> AggregatedResult {
        if page == 1, let existing = inflightFeed {
            return await existing.value
        }
        if page == 1 {
            let task = Task<AggregatedResult, Never> { [self] in
                await self._fetchFeed(page: page, pageSize: pageSize)
            }
            inflightFeed = task
            let result = await task.value
            inflightFeed = nil
            return result
        }
        return await _fetchFeed(page: page, pageSize: pageSize)
    }

    private func _fetchFeed(page: Int, pageSize: Int) async -> AggregatedResult {
        // Fetch from all sources concurrently
        async let newsResult = fetchNewsAPI(page: page, pageSize: pageSize)
        async let guardianArticles = fetchGuardian(page: page, pageSize: pageSize)
        async let nytResult = fetchNYT(page: page)
        async let gnewsArticles = fetchGNews(page: page)
        async let newsDataResult = fetchNewsData(page: page)
        async let hnArticles = fetchHackerNews()
        
        let (newsRes, guardianRes, nytRes, gnewsRes, newsDataRes, hnRes) = await (
            newsResult, guardianArticles, nytResult, gnewsArticles, newsDataResult, hnArticles
        )
        
        var allArticles = await combineAllSources(
            newsRes, guardianRes, nytRes, gnewsRes, newsDataRes, hnRes
        )
        
        // Apply smart scoring
        allArticles = await enhancedScorer.scoreAndEnrich(allArticles)
        
        // Apply topic diversity (max 2 articles per topic)
        allArticles = await topicDiversity.ensureDiversity(in: allArticles, maxPerTopic: 2)
        
        // Get user preferences for personalization boost
        let profile = await behaviorTracker.getUserProfile()
        allArticles = applyPersonalizationBoost(articles: allArticles, profile: profile)
        
        return AggregatedResult(
            articles: Array(allArticles.prefix(pageSize)),
            sourceCount: 6
        )
    }
    
    private func applyPersonalizationBoost(articles: [Article], profile: UserBehaviorTracker.UserPreferenceProfile) -> [Article] {
        return articles.map { article in
            var boosted = article
            if let sourceScore = profile.preferredSources[article.sourceName] {
                // Boost quality score based on user preferences
                let boost = sourceScore * 10
                boosted.qualityScore = (boosted.qualityScore ?? 50) + boost
            }
            return boosted
        }.sorted { ($0.qualityScore ?? 0) > ($1.qualityScore ?? 0) }
    }

    private func fetchNewsAPI(page: Int, pageSize: Int) async -> PaginatedResult<Article>? {
        do {
            return try await newsAPIRepository.fetchAllArticles(page: page, pageSize: pageSize)
        } catch {
            NewsAptoLogger.shared.error("NewsAPI fetch failed: \(error)", category: "Network")
            return nil
        }
    }

    private func fetchGuardian(page: Int, pageSize: Int) async -> [Article]? {
        do {
            return try await guardianClient.search(query: nil, page: page, pageSize: pageSize * 2, section: nil)
        } catch {
            NewsAptoLogger.shared.error("Guardian fetch failed: \(error)", category: "Network")
            return nil
        }
    }

    private func fetchNYT(page: Int) async -> NYTSearchResult? {
        do {
            return try await nytClient.search(query: nil, page: page, section: nil)
        } catch {
            NewsAptoLogger.shared.error("NYT fetch failed: \(error)", category: "Network")
            return nil
        }
    }
    
    private func fetchGNews(page: Int) async -> [Article]? {
        do {
            return try await gnewsClient.fetchTopHeadlines(max: 20, page: page)
        } catch {
            NewsAptoLogger.shared.error("GNews fetch failed: \(error)", category: "Network")
            return nil
        }
    }
    
    private func fetchNewsData(page: Int) async -> NewsDataClient.NewsDataResult? {
        do {
            return try await newsDataClient.fetchLatestNews(page: page > 1 ? String(page) : nil)
        } catch {
            NewsAptoLogger.shared.error("NewsData fetch failed: \(error)", category: "Network")
            return nil
        }
    }
    
    private func fetchHackerNews() async -> [Article]? {
        do {
            return try await hackerNewsClient.fetchTopStories(limit: 15)
        } catch {
            NewsAptoLogger.shared.error("HackerNews fetch failed: \(error)", category: "Network")
            return nil
        }
    }

    private func combineAllSources(
        _ newsResult: PaginatedResult<Article>?,
        _ guardianArticles: [Article]?,
        _ nytResult: NYTSearchResult?,
        _ gnewsArticles: [Article]?,
        _ newsDataResult: NewsDataClient.NewsDataResult?,
        _ hnArticles: [Article]?
    ) async -> [Article] {
        // Apply source caps for diversity (max articles per source)
        let newsAPIItems = Array((newsResult?.items ?? []).prefix(8))
        let guardianItems = Array((guardianArticles ?? []).prefix(6))
        let nytItems = Array((nytResult?.articles ?? []).prefix(6))
        let gnewsItems = Array((gnewsArticles ?? []).prefix(6))
        let newsDataItems = Array((newsDataResult?.articles ?? []).prefix(6))
        let hnItems = Array((hnArticles ?? []).prefix(5))  // HackerNews gets fewer slots
        
        var allArticles: [Article] = []
        allArticles.append(contentsOf: newsAPIItems)
        allArticles.append(contentsOf: guardianItems)
        allArticles.append(contentsOf: nytItems)
        allArticles.append(contentsOf: gnewsItems)
        allArticles.append(contentsOf: newsDataItems)
        allArticles.append(contentsOf: hnItems)

        // Deduplicate by URL
        var seenURLs = Set<String>()
        return allArticles.filter { article in
            guard let url = article.url?.absoluteString else { return true }
            guard !seenURLs.contains(url) else { return false }
            seenURLs.insert(url)
            return true
        }
    }
}
