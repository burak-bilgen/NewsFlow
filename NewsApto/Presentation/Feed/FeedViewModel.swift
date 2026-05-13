import Foundation
import Combine
@MainActor
final class FeedViewModel: ObservableObject {
    enum State: Equatable {
        case idle, loading, ready, empty
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var articles: [Article] = []
    @Published private(set) var savedArticleIDs: Set<String> = []
    @Published private(set) var isRefreshing = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMorePages = true
    @Published var selectedCategory: String? = nil
    @Published var searchQuery: String = ""

    var filteredArticles: [Article] {
        var result = articles
        if let category = selectedCategory {
            result = result.filter { matchesCategory($0, category) }
        }
        let query = searchQuery.trimmingCharacters(in: .whitespaces).lowercased()
        if !query.isEmpty {
            result = result.filter {
                $0.title.lowercased().contains(query) ||
                ($0.description?.lowercased().contains(query) ?? false) ||
                $0.sourceName.lowercased().contains(query)
            }
        }
        return result
    }

    private let aggregator: NewsAggregating
    private let readingListUseCase: ManageReadingListUseCaseProtocol
    private let pageSize: Int
    private var currentPage = 1

    init(
        aggregator: NewsAggregating,
        readingListUseCase: ManageReadingListUseCaseProtocol,
        pageSize: Int = 30
    ) {
        self.aggregator = aggregator
        self.readingListUseCase = readingListUseCase
        self.pageSize = pageSize
    }

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
        if currentPage > 1 {
            appendUnique(result.articles)
        } else {
            articles = result.articles
            if currentPage == 1 { Task { await SentinelNotificationService.shared.evaluateAndNotify(articles: result.articles) } }
        }
        hasMorePages = result.articles.count >= pageSize
        savedArticleIDs = await savedIDs
        state = articles.isEmpty ? .empty : .ready
    }

    private func appendUnique(_ newArticles: [Article]) {
        let existing = Set(articles.map(\.id))
        articles.append(contentsOf: newArticles.filter { !existing.contains($0.id) })
    }

    private func matchesCategory(_ article: Article, _ category: String) -> Bool {
        CategoryMatcher.matches(article, category: category)
    }
}

// MARK: - Category Matcher (Uses Article.category with NLP fallback)

enum CategoryMatcher {
    // Map external API categories to our standard categories
    private static let categoryMappings: [String: String] = [
        // Technology mappings
        "technology": "technology", "tech": "technology", "science-and-technology": "technology",
        "computers": "technology", "internet": "technology", "gadgets": "technology",
        
        // Business mappings
        "business": "business", "economy": "business", "finance": "business",
        "money": "business", "markets": "business", "companies": "business",
        
        // Science mappings  
        "science": "science", "research": "science", "space": "science",
        "environment": "science", "climate": "science", "nature": "science",
        
        // Health mappings
        "health": "health", "wellness": "health", "medical": "health",
        "medicine": "health", "mental-health": "health", "fitness": "health",
        
        // Sports mappings
        "sports": "sports", "sport": "sports", "football": "sports",
        "basketball": "sports", "soccer": "sports", "tennis": "sports",
        
        // Entertainment mappings
        "entertainment": "entertainment", "arts": "entertainment", "culture": "entertainment",
        "movies": "entertainment", "music": "entertainment", "television": "entertainment",
        "arts-and-culture": "entertainment", "lifestyle": "entertainment",
        
        // Politics/World (mapped to business for now)
        "politics": "business", "world": "business", "news": "business",
        "us-news": "business", "uk-news": "business"
    ]
    
    // Fallback keyword matching for articles without category
    private static let keywords: [String: [String]] = [
        "technology": ["tech", "artificial intelligence", "ai", "digital", "computer", "software", "apple", "google", "microsoft", "crypto", "bitcoin", "quantum", "startup", "cybersecurity", "algorithm", "app", "smartphone", "cloud", "data", "robot", "automation"],
        "business": ["market", "economy", "stock", "finance", "bank", "trade", "merger", "investment", "earnings", "revenue", "profit", "corporate", "ceo", "company", "startup funding"],
        "science": ["science", "space", "research", "study", "climate change", "gene", "nasa", "dna", "species", "physics", "chemistry", "biology", "laboratory", "discovery", "experiment"],
        "health": ["health", "medical", "drug", "hospital", "doctor", "vaccine", "mental health", "wellness", "brain", "cancer", "disease", "pandemic", "treatment", "patient", "symptom"],
        "sports": ["sport", "game", "match", "team", "league", "olympic", "champion", "football", "soccer", "basketball", "tennis", "baseball", "player", "coach", "tournament"],
        "entertainment": ["entertainment", "movie", "film", "music", "celebrity", "tv", "streaming", "award", "actor", "artist", "netflix", "show", "album", "concert", "hollywood"]
    ]

    static func matches(_ article: Article, category: String) -> Bool {
        // First check if article has explicit category from API
        if let articleCategory = article.category?.lowercased() {
            let normalizedCategory = categoryMappings[articleCategory] ?? articleCategory
            if normalizedCategory == category {
                return true
            }
        }
        
        // Fallback to keyword matching on title/description
        guard let categoryKeywords = keywords[category] else { return true }
        let text = (article.title + " " + (article.description ?? "") + " " + article.sourceName).lowercased()
        return categoryKeywords.contains { text.contains($0) }
    }
}
