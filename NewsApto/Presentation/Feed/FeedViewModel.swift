import Foundation
import Combine

@MainActor
final class FeedViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let searchService = ArticleSearchService()
    
    init(
        aggregator: NewsAggregating,
        readingListUseCase: ManageReadingListUseCaseProtocol,
        pageSize: Int = 30
    ) {
        self.aggregator = aggregator
        self.readingListUseCase = readingListUseCase
        self.pageSize = pageSize
        
        setupSearchDebounce()
    }
    
    private func setupSearchDebounce() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .filter { !$0.isEmpty }
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)
    }
    
    private func performSearch(query: String) {
        Task {
            isSearching = true
            let results = await searchService.search(
                query: query,
                in: articles,
                options: .init(
                    fuzzyThreshold: 0.7,        // Allow some typos
                    maxResults: 50,
                    searchContentSnippet: true,
                    caseSensitive: false,
                    minRelevanceScore: 0.15     // Filter low-quality matches
                )
            )
            searchResults = results
            isSearching = false
        }
    }
    
    func clearSearch() {
        searchQuery = ""
        searchResults = []
    }
    enum State: Equatable {
        case idle, loading, ready, empty, error(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var articles: [Article] = []
    @Published private(set) var savedArticleIDs: Set<String> = []
    @Published private(set) var isRefreshing = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMorePages = true
    @Published var searchQuery: String = ""
    @Published private(set) var searchResults: [ArticleSearchService.SearchResult] = []
    @Published private(set) var isSearching = false
    @Published private(set) var errorMessage: String?
    @Published var selectedCategory: String? = nil

    private static let categoryKeywords: [(name: String, keywords: [String])] = [
        ("technology", ["tech", "apple", "google", "microsoft", "ai", "software", "startup", "cyber", "digital", "code", "app", "iphone", "android", "robot", "computer", "data", "algorithm", "program", "chip", "semiconductor", "electric", "autonomous", "blockchain", "crypto"]),
        ("science", ["science", "study", "research", "nasa", "space", "dna", "climate", "nature", "physics", "biology", "chemistry", "medical", "gene", "evolution", "planet", "mars", "moon", "quantum", "lab"]),
        ("health", ["health", "covid", "vaccine", "hospital", "drug", "disease", "patient", "doctor", "mental", "pandemic", "virus", "fda", "treatment", "surgery", "wellness", "medicine", "nutrition"]),
        ("business", ["business", "market", "stock", "economy", "trade", "bank", "finance", "merger", "ipo", "revenue", "profit", "ceo", "startup", "investment", "fund", "dollar", "inflation", "crypto"]),
        ("sports", ["sport", "nba", "nfl", "soccer", "football", "basketball", "tennis", "champion", "olympic", "player", "coach", "league", "mlb", "nhl", "fifa", "athlete", "world cup", "super bowl"]),
        ("entertainment", ["movie", "film", "music", "actor", "actress", "game", "hollywood", "netflix", "concert", "album", "award", "oscar", "celebrity", "theatre", "stream", "artist", "show", "tv", "series"]),
        ("general", ["news", "world", "president", "government", "election", "congress", "senate", "law", "policy", "military", "war", "attack", "treaty", "minister", "court", "protest", "interview"])
    ]

    private func detectCategory(for article: Article) -> String {
        let text = (article.title + " " + (article.description ?? "")).lowercased()
        var scores: [(String, Int)] = Self.categoryKeywords.map { category, keywords in
            (category, keywords.filter { text.contains($0) }.count)
        }
        scores.sort { $0.1 > $1.1 }
        return scores.first?.0 ?? "general"
    }

    var availableCategories: [String] {
        let all = Set(articles.map { detectCategory(for: $0) })
        return ["technology", "science", "health", "business", "sports", "entertainment", "general"].filter { all.contains($0) }
    }

    var filteredByCategory: [Article] {
        let searched = filteredArticles
        guard let category = selectedCategory else { return searched }
        return searched.filter { detectCategory(for: $0) == category }
    }
    
    var filteredArticles: [Article] {
        let query = searchQuery.trimmingCharacters(in: .whitespaces)
        if query.isEmpty {
            return articles
        }
        return searchResults.map { $0.article }
    }
    
    var searchResultDetails: [ArticleSearchService.SearchResult] {
        return searchResults
    }

    private let aggregator: NewsAggregating
    private let readingListUseCase: ManageReadingListUseCaseProtocol
    private let pageSize: Int
    private var currentPage = 1

    func loadIfNeeded() async {
        guard case .idle = state else { return }
        state = .loading
        await fetch()
    }

    func pullToRefresh() async {
        isRefreshing = true
        isLoadingMore = false
        currentPage = 1
        hasMorePages = true
        await fetch()
        isRefreshing = false
    }

    func loadMore() async {
        guard hasMorePages, !isLoadingMore else { return }
        isLoadingMore = true
        currentPage += 1
        await fetch()
        isLoadingMore = false
    }

    func prefetchIfNeeded(currentItem: Article) {
        let items = filteredArticles
        guard let index = items.firstIndex(where: { $0.id == currentItem.id }) else { return }
        let threshold = items.count - 5
        if index >= threshold {
            Task { await loadMore() }
        }
    }

    func isSaved(_ article: Article) -> Bool { savedArticleIDs.contains(article.id) }

    func toggleReadingList(for article: Article) async {
        if let result = try? await readingListUseCase.toggle(article) {
            if result { savedArticleIDs.insert(article.id) } else { savedArticleIDs.remove(article.id) }
        }
    }

    private func fetch() async {
        let result = await aggregator.fetchFeed(page: currentPage, pageSize: pageSize)
        async let savedIDs = readingListUseCase.savedArticleIDs()
        
        let scorer = EnhancedArticleScorer()
        let scoredArticles = await scorer.scoreAndEnrichWithDuplicates(result.articles)
        
        if currentPage > 1 {
            appendUnique(scoredArticles)
        } else {
            articles = scoredArticles
            if currentPage == 1 { Task { await SentinelNotificationService.shared.evaluateAndNotify(articles: scoredArticles) } }
        }
        hasMorePages = result.articles.count >= pageSize
        savedArticleIDs = await savedIDs
        if result.sourceCount == 0 && articles.isEmpty {
            state = .error("All news sources are currently unavailable")
        } else {
            state = articles.isEmpty ? .empty : .ready
        }
    }

    private func appendUnique(_ newArticles: [Article]) {
        let existing = Set(articles.map(\.id))
        articles.append(contentsOf: newArticles.filter { !existing.contains($0.id) })
    }
}
