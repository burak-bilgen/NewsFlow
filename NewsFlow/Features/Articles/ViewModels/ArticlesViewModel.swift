import Combine
import Foundation

// MARK: - ArticlesViewModel

/// Manages the state and business logic for the Articles screen.
///
/// Key design decisions:
/// - `@MainActor` keeps all `@Published` updates on the main thread safely.
/// - `latestRequestID` acts as a request nonce. If a newer request starts before
///   the old one finishes, stale callbacks are ignored. This prevents race
///   conditions when the user rapidly pulls to refresh.
/// - `FetchMode` distinguishes UI-driven loads (initial/retry) from silent
///   background refreshes (automatic) so we don't show full-screen spinners
///   when auto-refreshing every 60s.
/// - Pagination: page 1 is cached, subsequent pages append to the list.
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
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var articles: [Article] = []
    @Published private(set) var savedArticleIDs: Set<String> = []
    @Published private(set) var isRefreshing = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMorePages = true
    @Published var carouselSelection = 0
    @Published var warningMessage: String?

    let source: NewsSource

    private let articlesRepository: ArticlesRepositoryProtocol
    private let readingListRepository: ReadingListRepositoryProtocol
    private let sortingStrategy: ArticleSorting
    private let errorSimulator: ArticleRequestErrorSimulating?
    private let pageSize: Int

    /// Unique ID for the most recent fetch request. Used to drop stale callbacks.
    private var latestRequestID = UUID()
    private var automaticRefreshTask: Task<Void, Never>?
    private var currentPage = 1

    init(
        source: NewsSource,
        articlesRepository: ArticlesRepositoryProtocol,
        readingListRepository: ReadingListRepositoryProtocol,
        sortingStrategy: ArticleSorting = ArticleSorter(),
        errorSimulator: ArticleRequestErrorSimulating? = nil,
        pageSize: Int = 20
    ) {
        self.source = source
        self.articlesRepository = articlesRepository
        self.readingListRepository = readingListRepository
        self.sortingStrategy = sortingStrategy
        self.errorSimulator = errorSimulator
        self.pageSize = pageSize
    }

    deinit {
        automaticRefreshTask?.cancel()
    }

    /// First 3 articles become the hero carousel.
    var featuredArticles: [Article] {
        Array(articles.prefix(3))
    }

    /// Remaining articles appear in the thumbnail list below.
    var listArticles: [Article] {
        Array(articles.dropFirst(3))
    }

    /// Loads articles only on first appearance. Prevents re-loading on re-appear.
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
        currentPage = 1
        await fetch(mode: .retry)
    }

    /// Loads the next page of articles for infinite scrolling.
    func loadMore() async {
        guard !isLoadingMore, hasMorePages else { return }
        currentPage += 1
        await fetch(mode: .loadMore)
    }

    /// Starts a background task that silently refreshes every 60 seconds.
    /// Cancelled automatically when the view disappears (via `deinit`).
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
    /// Convenience for SwiftUI Previews — sets state without triggering network.
    func withState(_ newState: State) -> Self {
        state = newState
        return self
    }
    #endif

    func toggleReadingList(for article: Article) async {
        do {
            let isSaved = try await readingListRepository.toggle(article)
            if isSaved {
                savedArticleIDs.insert(article.id)
            } else {
                savedArticleIDs.remove(article.id)
            }
        } catch {
            warningMessage = L10n.text("error.generic")
        }
    }

    // MARK: - Private

    /// The core fetch pipeline. Handles loading states, error simulation,
    /// parallel async requests, and stale-request cancellation.
    private func fetch(mode: FetchMode) async {
        let requestID = UUID()
        latestRequestID = requestID

        // Show full-screen skeleton on initial load or retry.
        // Pull-to-refresh uses the ScrollView's built-in indicator instead.
        if mode == .initial || mode == .retry {
            state = .loading
        } else if mode == .loadMore {
            isLoadingMore = true
        } else if mode != .automatic {
            isRefreshing = true
        }

        // Debug feature: every 3rd non-automatic request fails on purpose.
        if let errorSimulator, mode != .automatic, await errorSimulator.shouldSimulateError() {
            guard latestRequestID == requestID else { return }
            resetLoadingState(mode: mode)
            warningMessage = L10n.text("error.simulatedFetch")
            if articles.isEmpty {
                state = .error(L10n.text("error.simulatedFetch"))
            }
            return
        }

        do {
            // Fetch articles and saved IDs in parallel — they're independent.
            async let fetchedResult = articlesRepository.fetchArticles(
                sourceID: source.id,
                page: currentPage,
                pageSize: pageSize
            )
            async let savedIDs = readingListRepository.savedArticleIDs()
            let result = try await (fetchedResult, savedIDs)

            // Drop this callback if a newer request started while we were waiting.
            guard latestRequestID == requestID else { return }
            handleFetchSuccess(result.0, savedIDs: result.1, mode: mode, requestID: requestID)
        } catch let error as NewsAPIError where error == .cancelled {
            // User cancelled (e.g. view disappeared) — just reset the flag.
            resetLoadingState(mode: mode)
        } catch let error as NewsAPIError {
            guard latestRequestID == requestID else { return }
            handleFetchError(error.userMessage, requestID: requestID, mode: mode)
        } catch {
            guard latestRequestID == requestID else { return }
            handleFetchError(L10n.text("error.generic"), requestID: requestID, mode: mode)
        }
    }

    /// Updates the UI with fresh data. For automatic refreshes, silently
    /// skips if nothing changed so the user isn't interrupted.
    private func handleFetchSuccess(
        _ result: PaginatedResult<Article>,
        savedIDs: Set<String>,
        mode: FetchMode,
        requestID: UUID
    ) {
        if mode == .loadMore {
            // Append new articles instead of replacing
            let existingIDs = Set(articles.map(\.id))
            let newArticles = result.items.filter { !existingIDs.contains($0.id) }
            articles.append(contentsOf: newArticles)
        } else {
            let sorted = sortingStrategy.newestFirst(result.items)

            // Automatic refresh: don't disturb the UI if articles haven't changed.
            if mode == .automatic, sorted.map(\.id) == articles.map(\.id) {
                resetLoadingState(mode: mode)
                return
            }

            articles = sorted
        }

        hasMorePages = result.hasMorePages
        savedArticleIDs = savedIDs
        carouselSelection = min(carouselSelection, max(featuredArticles.count - 1, 0))
        warningMessage = nil
        resetLoadingState(mode: mode)
        state = articles.isEmpty ? .empty : .loaded
    }

    private func handleFetchError(_ message: String, requestID: UUID, mode: FetchMode) {
        guard latestRequestID == requestID else { return }
        resetLoadingState(mode: mode)
        if articles.isEmpty {
            state = .error(message)
        }
        warningMessage = message
    }

    private func resetLoadingState(mode: FetchMode) {
        if mode == .loadMore {
            isLoadingMore = false
        } else {
            isRefreshing = false
        }
    }
}
