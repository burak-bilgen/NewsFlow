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
        
        // Collect ALL articles from all sources - NO FILTERING
        var allArticles: [Article] = []
        allArticles.append(contentsOf: newsRes?.items ?? [])
        allArticles.append(contentsOf: guardianRes ?? [])
        allArticles.append(contentsOf: nytRes?.articles ?? [])
        allArticles.append(contentsOf: gnewsRes ?? [])
        allArticles.append(contentsOf: newsDataRes?.articles ?? [])
        allArticles.append(contentsOf: hnRes ?? [])
        
        // Only sort by quality score - NO filtering, NO caps, NO diversity limits
        allArticles = await enhancedScorer.scoreAndEnrich(allArticles)
        
        return AggregatedResult(
            articles: allArticles,
            sourceCount: 6
        )
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
}
