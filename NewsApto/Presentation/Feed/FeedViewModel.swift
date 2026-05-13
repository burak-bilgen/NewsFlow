import Combine
import Foundation

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

    private let aggregator: NewsAggregatorService
    private let readingListUseCase: ManageReadingListUseCaseProtocol
    private let pageSize: Int
    private var currentPage = 1

    init(
        aggregator: NewsAggregatorService,
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
        let text = (article.title + " " + (article.description ?? "") + " " + article.sourceName).lowercased()
        switch category {
        case "technology": return text.contains("tech") || text.contains("ai ") || text.contains("digital") || text.contains("computer") || text.contains("software") || text.contains("apple") || text.contains("google") || text.contains("microsoft") || text.contains("crypto") || text.contains("bitcoin") || text.contains("quantum") || text.contains("startup")
        case "business": return text.contains("market") || text.contains("economy") || text.contains("stock") || text.contains("finance") || text.contains("bank") || text.contains("trade") || text.contains("merger") || text.contains("investment") || text.contains("earnings")
        case "science": return text.contains("science") || text.contains("space") || text.contains("research") || text.contains("study") || text.contains("climate") || text.contains("gene") || text.contains("quantum") || text.contains("nasa") || text.contains("dna") || text.contains("species")
        case "health": return text.contains("health") || text.contains("medical") || text.contains("drug") || text.contains("hospital") || text.contains("doctor") || text.contains("vaccine") || text.contains("mental") || text.contains("wellness") || text.contains("brain") || text.contains("cancer")
        case "sports": return text.contains("sport") || text.contains("game") || text.contains("match") || text.contains("team") || text.contains("league") || text.contains("olympic") || text.contains("champion") || text.contains("football") || text.contains("soccer") || text.contains("basketball")
        case "entertainment": return text.contains("entertainment") || text.contains("movie") || text.contains("film") || text.contains("music") || text.contains("celebrity") || text.contains("tv ") || text.contains("streaming") || text.contains("award") || text.contains("actor") || text.contains("artist")
        default: return true
        }
    }
}
