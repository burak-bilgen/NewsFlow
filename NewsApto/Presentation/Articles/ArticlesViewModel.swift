import Combine
import Foundation

@MainActor
final class ArticlesViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case empty
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var articles: [Article] = []
    @Published private(set) var savedArticleIDs: Set<String> = []
    @Published private(set) var isRefreshing = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var isPrefetching = false
    @Published private(set) var hasMorePages = true
    @Published var carouselSelection = 0
    @Published var searchQuery: String = ""
    @Published var isSearching: Bool = false
    let source: NewsSource
    private var searchTask: Task<Void, Never>?
    private let fetchUseCase: FetchArticlesUseCaseProtocol
    private let readingListUseCase: ManageReadingListUseCaseProtocol
    private let pageSize: Int
    private var latestRequestID = UUID()
    private var currentPage = 1
    private var searchCurrentPage = 1

    init(
        source: NewsSource,
        fetchUseCase: FetchArticlesUseCaseProtocol,
        readingListUseCase: ManageReadingListUseCaseProtocol,
        pageSize: Int = 20
    ) {
        self.source = source
        self.fetchUseCase = fetchUseCase
        self.readingListUseCase = readingListUseCase
        self.pageSize = pageSize
    }

    deinit {
        searchTask?.cancel()
    }

    var featuredArticles: [Article] { Array(articles.prefix(3)) }
    var listArticles: [Article] { Array(articles.dropFirst(3)) }

    func loadIfNeeded() async {
        guard case .idle = state else { return }
        state = .loading
        await fetch()
    }

    func pullToRefresh() async {
        currentPage = 1
        isRefreshing = true
        await fetch()
        isRefreshing = false
    }

    func loadMore() async {
        if isSearching { await loadMoreSearch(); return }
        guard !isLoadingMore, hasMorePages else { return }
        currentPage += 1
        isLoadingMore = true
        await fetch(append: true)
        isLoadingMore = false
    }

    func isSaved(_ article: Article) -> Bool { savedArticleIDs.contains(article.id) }

    func updateSearchQuery(_ query: String) {
        searchQuery = query
        searchTask?.cancel()
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            isSearching = false; hasMorePages = true; currentPage = 1
            Task { state = .loading; await fetch() }
            return
        }
        isSearching = true; searchCurrentPage = 1
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            await performSearch(query)
        }
    }

    private func performSearch(_ query: String) async {
        state = .loading
        do {
            let result = try await fetchUseCase.searchArticles(query: query, page: 1, pageSize: pageSize)
            articles = result.items; state = result.items.isEmpty ? .empty : .loaded
            hasMorePages = result.hasMorePages
        } catch {
            if articles.isEmpty { state = .empty }
        }
    }

    private func loadMoreSearch() async {
        guard !isLoadingMore, hasMorePages else { return }
        isLoadingMore = true; searchCurrentPage += 1
        do {
            let result = try await fetchUseCase.searchArticles(query: searchQuery, page: searchCurrentPage, pageSize: pageSize)
            let existing = Set(articles.map(\.id))
            articles.append(contentsOf: result.items.filter { !existing.contains($0.id) })
            hasMorePages = result.hasMorePages
        } catch { searchCurrentPage -= 1 }
        isLoadingMore = false
    }

    func toggleReadingList(for article: Article) async {
        if let result = try? await readingListUseCase.toggle(article) {
            if result { savedArticleIDs.insert(article.id) } else { savedArticleIDs.remove(article.id) }
        }
    }

    func prefetchNextPageIfNeeded() async {
        guard !isPrefetching, !isLoadingMore, hasMorePages, state == .loaded else { return }
        isPrefetching = true
        currentPage += 1
        await fetch(append: true)
        isPrefetching = false
    }

    func prefetchImages(for visibleArticles: [Article]) {
        let urls = visibleArticles.compactMap { $0.imageURL }
        Task { await ImageCacheAdapter().preloadImages(from: urls, targetSize: CGSize(width: 200, height: 200)) }
    }

    private func fetch(append: Bool = false) async {
        let requestID = UUID()
        latestRequestID = requestID
        do {
            async let fetchedResult = fetchUseCase.execute(sourceID: source.id, page: currentPage, pageSize: pageSize, bypassCache: false)
            async let savedIDs = readingListUseCase.savedArticleIDs()
            let result = try await (fetchedResult, savedIDs)
            guard latestRequestID == requestID else { return }
            if append {
                let existing = Set(articles.map(\.id))
                articles.append(contentsOf: result.0.items.filter { !existing.contains($0.id) })
            } else { articles = result.0.items }
            hasMorePages = result.0.hasMorePages
            savedArticleIDs = result.1
            carouselSelection = min(carouselSelection, max(featuredArticles.count - 1, 0))
            state = articles.isEmpty ? .empty : .loaded
        } catch {
            guard latestRequestID == requestID else { return }
            if append { currentPage -= 1 }
            if articles.isEmpty { state = .empty }
        }
    }
}
