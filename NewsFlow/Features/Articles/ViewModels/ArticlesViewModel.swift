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
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var articles: [Article] = []
    @Published private(set) var savedArticleIDs: Set<String> = []
    @Published private(set) var isRefreshing = false
    @Published var carouselSelection = 0
    @Published var warningMessage: String?

    let source: NewsSource

    private let articlesRepository: ArticlesRepositoryProtocol
    private let readingListRepository: ReadingListRepositoryProtocol
    private let sortingStrategy: ArticleSorting
    private let errorSimulator: ArticleRequestErrorSimulating?

    /// Unique ID for the most recent fetch request. Used to drop stale callbacks.
    private var latestRequestID = UUID()
    private var automaticRefreshTask: Task<Void, Never>?

    init(
        source: NewsSource,
        articlesRepository: ArticlesRepositoryProtocol,
        readingListRepository: ReadingListRepositoryProtocol,
        sortingStrategy: ArticleSorting = ArticleSorter(),
        errorSimulator: ArticleRequestErrorSimulating? = nil
    ) {
        self.source = source
        self.articlesRepository = articlesRepository
        self.readingListRepository = readingListRepository
        self.sortingStrategy = sortingStrategy
        self.errorSimulator = errorSimulator
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
        await fetch(mode: .initial)
    }

    func pullToRefresh() async {
        await fetch(mode: .pullToRefresh)
    }

    func retry() async {
        await fetch(mode: .retry)
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
        } else if mode != .automatic {
            isRefreshing = true
        }

        // Debug feature: every 3rd non-automatic request fails on purpose.
        if let errorSimulator, mode != .automatic, await errorSimulator.shouldSimulateError() {
            guard latestRequestID == requestID else { return }
            isRefreshing = false
            warningMessage = L10n.text("error.simulatedFetch")
            state = articles.isEmpty ? .error(L10n.text("error.simulatedFetch")) : .loaded
            return
        }

        do {
            // Fetch articles and saved IDs in parallel — they're independent.
            async let fetchedArticles = articlesRepository.fetchArticles(sourceID: source.id)
            async let savedIDs = readingListRepository.savedArticleIDs()
            let result = try await (fetchedArticles, savedIDs)

            // Drop this callback if a newer request started while we were waiting.
            guard latestRequestID == requestID else { return }
            handleFetchSuccess(result.0, savedIDs: result.1, mode: mode, requestID: requestID)
        } catch let error as NewsAPIError where error == .cancelled {
            // User cancelled (e.g. view disappeared) — just reset the flag.
            isRefreshing = false
        } catch let error as NewsAPIError {
            guard latestRequestID == requestID else { return }
            handleFetchError(error.userMessage, requestID: requestID)
        } catch {
            guard latestRequestID == requestID else { return }
            handleFetchError(L10n.text("error.generic"), requestID: requestID)
        }
    }

    /// Updates the UI with fresh data. For automatic refreshes, silently
    /// skips if nothing changed so the user isn't interrupted.
    private func handleFetchSuccess(_ fetched: [Article], savedIDs: Set<String>, mode: FetchMode, requestID: UUID) {
        let sorted = sortingStrategy.newestFirst(fetched)

        // Automatic refresh: don't disturb the UI if articles haven't changed.
        if mode == .automatic, sorted.map(\.id) == articles.map(\.id) {
            isRefreshing = false
            return
        }

        articles = sorted
        savedArticleIDs = savedIDs
        carouselSelection = min(carouselSelection, max(featuredArticles.count - 1, 0))
        warningMessage = nil
        isRefreshing = false
        state = articles.isEmpty ? .empty : .loaded
    }

    private func handleFetchError(_ message: String, requestID: UUID) {
        guard latestRequestID == requestID else { return }
        isRefreshing = false
        state = articles.isEmpty ? .error(message) : .loaded
        warningMessage = message
    }
}
