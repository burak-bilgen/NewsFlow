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
    private let scorer = SmartArticleScorer()
    private var inflightFeed: Task<AggregatedResult, Never>?

    init(
        newsAPIRepository: ArticlesRepositoryProtocol,
        guardianClient: GuardianClientProtocol,
        nytClient: NYTClientProtocol
    ) {
        self.newsAPIRepository = newsAPIRepository
        self.guardianClient = guardianClient
        self.nytClient = nytClient
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
        let newsResult = await fetchNewsAPI(page: page, pageSize: pageSize)
        let guardianArticles = await fetchGuardian(page: page, pageSize: pageSize)
        let nytResult = await fetchNYT(page: page)

        return combine(newsResult, guardianArticles, nytResult)
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

    func fetchArticles(sourceID: String, page: Int = 1, pageSize: Int = 20) async -> AggregatedResult {
        let newsResult: PaginatedResult<Article>? = await {
            do {
                return try await newsAPIRepository.fetchArticles(sourceID: sourceID, page: page, pageSize: pageSize)
            } catch {
                NewsAptoLogger.shared.error("NewsAPI fetch failed for \(sourceID): \(error)", category: "Network")
                return nil
            }
        }()
        let guardianArticles: [Article]? = await {
            do {
                return try await guardianClient.search(query: nil, page: page, pageSize: pageSize, section: sourceID == "all" ? nil : sourceID)
            } catch {
                NewsAptoLogger.shared.error("Guardian fetch failed for \(sourceID): \(error)", category: "Network")
                return nil
            }
        }()
        let nytResult: NYTSearchResult? = await {
            do {
                return try await nytClient.search(query: nil, page: page, section: sourceID == "all" ? nil : sourceID)
            } catch {
                NewsAptoLogger.shared.error("NYT fetch failed for \(sourceID): \(error)", category: "Network")
                return nil
            }
        }()

        return combine(newsResult, guardianArticles, nytResult)
    }

    private func combine(_ newsResult: PaginatedResult<Article>?, _ guardianArticles: [Article]?, _ nytResult: NYTSearchResult?) -> AggregatedResult {
        var allArticles: [Article] = []
        var sourceCount = 0

        if let paginated = newsResult {
            allArticles.append(contentsOf: paginated.items)
            sourceCount += 1
        }
        if let articles = guardianArticles {
            allArticles.append(contentsOf: articles)
            sourceCount += 1
        }
        if let result = nytResult {
            allArticles.append(contentsOf: result.articles)
            sourceCount += 1
        }

        let sorted = scorer.sortAndDeduplicate(allArticles)
        return AggregatedResult(articles: sorted, sourceCount: sourceCount)
    }
}
