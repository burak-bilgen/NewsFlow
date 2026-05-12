import Combine
import Foundation

// MARK: - ArticlesViewModel

/// Manages presentation state for the Articles screen.
/// Business logic is delegated to Use Cases.
@MainActor
final class ArticlesViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case empty
        case error(String)
    }

    enum FetchMode {
        case initial
        case pullToRefresh
        case retry
        case automatic
        case loadMore
        case prefetch
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
    private var automaticRefreshTask: Task<Void, Never>?
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
        automaticRefreshTask?.cancel()
        searchTask?.cancel()
    }

    var featuredArticles: [Article] {
        Array(articles.prefix(3))
    }

    var listArticles: [Article] {
        Array(articles.dropFirst(3))
    }

    func loadIfNeeded() async {
        guard case .idle = state else { return }
        currentPage = 1
        await fetch(mode: .initial)
    }

    func pullToRefresh() async {
        currentPage = 1
        await fetch(mode: .pullToRefresh)
    }

    func retry() async {
        ToastManager.shared.dismiss()
        currentPage = 1
        await fetch(mode: .retry)
    }

    func loadMore() async {
        if isSearching {
            await loadMoreSearch()
            return
        }
        guard !isLoadingMore, hasMorePages else { return }
        currentPage += 1
        await fetch(mode: .loadMore)
    }

    func prefetchNextPageIfNeeded() async {
        guard !isPrefetching, !isLoadingMore, hasMorePages, state == .loaded else { return }
        isPrefetching = true
        currentPage += 1
        await fetch(mode: .prefetch)
        isPrefetching = false
    }

    func prefetchImages(for visibleArticles: [Article]) {
        let urls = visibleArticles.compactMap { $0.imageURL }
        Task { @MainActor in
            await ImageCacheAdapter().preloadImages(from: urls, targetSize: CGSize(width: 200, height: 200))
        }
    }

    func startAutomaticRefresh() {
        guard automaticRefreshTask == nil else { return }
        automaticRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60_000_000_000)
                guard !Task.isCancelled else { return }
                await self?.fetch(mode: .automatic)
            }
        }
    }

    func stopAutomaticRefresh() {
        automaticRefreshTask?.cancel()
        automaticRefreshTask = nil
    }

    func isSaved(_ article: Article) -> Bool {
        savedArticleIDs.contains(article.id)
    }

    #if DEBUG
    func withState(_ newState: State) -> Self {
        state = newState
        return self
    }
    #endif

    func updateSearchQuery(_ query: String) {
        searchQuery = query
        searchTask?.cancel()

        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            isSearching = false
            hasMorePages = true
            currentPage = 1
            Task { await fetch(mode: .initial) }
            return
        }

        isSearching = true
        searchCurrentPage = 1
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
            if result.items.isEmpty {
                articles = []
                state = .empty
                NewsFlowLogger.shared.info("Search returned no results for: \(query)", category: "Search")
            } else {
                articles = result.items
                state = .loaded
                NewsFlowLogger.shared.debug("Search found \(result.items.count) results for: \(query)", category: "Search")
            }
            currentPage = 1
            hasMorePages = result.hasMorePages
        } catch {
            NewsFlowLogger.shared.error("Search failed: \(error.localizedDescription)", category: "Search")
            if articles.isEmpty {
                state = .error(L10n.text("error.generic"))
            }
            currentPage = 1
        }
    }

    private func loadMoreSearch() async {
        guard !isLoadingMore, hasMorePages else { return }
        isLoadingMore = true
        searchCurrentPage += 1
        do {
            let result = try await fetchUseCase.searchArticles(query: searchQuery, page: searchCurrentPage, pageSize: pageSize)
            let existingIDs = Set(articles.map(\.id))
            let uniqueNewItems = result.items.filter { !existingIDs.contains($0.id) }
            articles.append(contentsOf: uniqueNewItems)
            hasMorePages = result.hasMorePages
            NewsFlowLogger.shared.debug("Search load more added \(uniqueNewItems.count) items", category: "Search")
        } catch {
            NewsFlowLogger.shared.error("Search load more failed: \(error.localizedDescription)", category: "Search")
            searchCurrentPage -= 1
            ToastManager.shared.show(
                L10n.text("error.generic"),
                style: .error,
                duration: 5.0
            )
        }
        isLoadingMore = false
    }

    func toggleReadingList(for article: Article) async {
        do {
            let isSaved = try await readingListUseCase.toggle(article)
            if isSaved {
                savedArticleIDs.insert(article.id)
            } else {
                savedArticleIDs.remove(article.id)
            }
        } catch {
            ToastManager.shared.show(
                L10n.text("error.generic"),
                style: .error,
                action: ToastAction(title: L10n.text("retry.button")) { [weak self] in
                    Task { await self?.toggleReadingList(for: article) }
                }
            )
        }
    }

    // MARK: - Private

    private func fetch(mode: FetchMode) async {
        let requestID = UUID()
        latestRequestID = requestID

        applyLoadingState(for: mode)

        do {
            let bypassCache = mode == .pullToRefresh || mode == .retry
            async let fetchedResult = fetchUseCase.execute(
                sourceID: source.id,
                page: currentPage,
                pageSize: pageSize,
                bypassCache: bypassCache
            )
            async let savedIDs = readingListUseCase.savedArticleIDs()
            let result = try await (fetchedResult, savedIDs)

            guard latestRequestID == requestID else { return }
            handleFetchSuccess(result.0, savedIDs: result.1, mode: mode)
        } catch let error as NewsAPIError where error == .cancelled {
            resetLoadingState(mode: mode)
        } catch {
            guard latestRequestID == requestID else { return }
            handleFetchError(error, mode: mode)
        }
    }

    private func applyLoadingState(for mode: FetchMode) {
        switch mode {
        case .initial, .retry:
            state = .loading
        case .loadMore:
            isLoadingMore = true
        case .pullToRefresh:
            isRefreshing = true
        case .automatic, .prefetch:
            break
        }
    }

    private func handleFetchSuccess(
        _ result: PaginatedResult<Article>,
        savedIDs: Set<String>,
        mode: FetchMode
    ) {
        if mode == .loadMore {
            appendNewArticles(result.items)
        } else {
            if mode == .automatic, result.items.map(\.id) == articles.map(\.id) {
                resetLoadingState(mode: mode)
                return
            }
            articles = result.items
        }

        hasMorePages = result.hasMorePages
        savedArticleIDs = savedIDs
        carouselSelection = min(carouselSelection, max(featuredArticles.count - 1, 0))
        resetLoadingState(mode: mode)
        state = articles.isEmpty ? .empty : .loaded
    }

    private func appendNewArticles(_ newItems: [Article]) {
        let existingIDs = Set(articles.map(\.id))
        let uniqueNewItems = newItems.filter { !existingIDs.contains($0.id) }
        articles.append(contentsOf: uniqueNewItems)
    }

    private func handleFetchError(_ error: Error, mode: FetchMode) {
        let message = (error as? NewsAPIError)?.userMessage ?? L10n.text("error.generic")
        resetLoadingState(mode: mode)
        if articles.isEmpty {
            state = .error(message)
        }
        ToastManager.shared.show(
            message,
            style: .error,
            duration: 5.0,
            action: ToastAction(title: L10n.text("retry.button")) { [weak self] in
                Task { await self?.retry() }
            }
        )
    }

    private func resetLoadingState(mode: FetchMode) {
        switch mode {
        case .loadMore:
            isLoadingMore = false
        case .pullToRefresh:
            isRefreshing = false
        case .automatic, .prefetch, .initial, .retry:
            break
        }
    }
}
