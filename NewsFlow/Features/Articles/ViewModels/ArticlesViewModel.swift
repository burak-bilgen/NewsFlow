import Foundation
import Combine

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
    private let errorSimulator: ArticleRequestErrorSimulating?
    private var latestRequestID = UUID()
    private var automaticRefreshTask: Task<Void, Never>?

    init(
        source: NewsSource,
        articlesRepository: ArticlesRepositoryProtocol,
        readingListRepository: ReadingListRepositoryProtocol,
        errorSimulator: ArticleRequestErrorSimulating? = nil
    ) {
        self.source = source
        self.articlesRepository = articlesRepository
        self.readingListRepository = readingListRepository
        self.errorSimulator = errorSimulator
    }

    deinit {
        automaticRefreshTask?.cancel()
    }

    var featuredArticles: [Article] {
        Array(articles.prefix(3))
    }

    var listArticles: [Article] {
        Array(articles.dropFirst(3))
    }

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

    private func fetch(mode: FetchMode) async {
        let requestID = UUID()
        latestRequestID = requestID

        if mode == .initial {
            state = .loading
        } else if mode != .automatic {
            isRefreshing = true
        }

        if let errorSimulator, mode != .automatic, await errorSimulator.shouldSimulateError() {
            guard latestRequestID == requestID else { return }
            isRefreshing = false
            warningMessage = L10n.text("error.simulatedFetch")
            state = articles.isEmpty ? .error(L10n.text("error.simulatedFetch")) : .loaded
            return
        }

        do {
            async let fetchedArticles = articlesRepository.fetchArticles(sourceID: source.id)
            async let savedIDs = readingListRepository.savedArticleIDs()
            let result = try await (fetchedArticles, savedIDs)
            guard latestRequestID == requestID else { return }

            handleFetchSuccess(result.0, savedIDs: result.1, mode: mode, requestID: requestID)
        } catch let error as NewsAPIError where error == .cancelled {
            isRefreshing = false
        } catch let error as NewsAPIError {
            guard latestRequestID == requestID else { return }
            handleFetchError(error.userMessage, requestID: requestID)
        } catch {
            guard latestRequestID == requestID else { return }
            handleFetchError(L10n.text("error.generic"), requestID: requestID)
        }
    }

    private func handleFetchSuccess(_ fetched: [Article], savedIDs: Set<String>, mode: FetchMode, requestID: UUID) {
        let sorted = ArticleSorter.newestFirst(fetched)
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
