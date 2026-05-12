import Combine
import Foundation

@MainActor
final class FeedViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case empty
        case error(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var articles: [Article] = []
    @Published private(set) var savedArticleIDs: Set<String> = []
    @Published private(set) var isRefreshing = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMorePages = true
    @Published var carouselSelection = 0

    var featuredArticles: [Article] { Array(articles.prefix(3)) }
    var listArticles: [Article] { Array(articles.dropFirst(3)) }

    private let feedUseCase: FetchFeedUseCaseProtocol
    private let readingListUseCase: ManageReadingListUseCaseProtocol
    private let pageSize: Int
    private var currentPage = 1
    private var latestRequestID = UUID()

    init(
        feedUseCase: FetchFeedUseCaseProtocol,
        readingListUseCase: ManageReadingListUseCaseProtocol,
        pageSize: Int = 30
    ) {
        self.feedUseCase = feedUseCase
        self.readingListUseCase = readingListUseCase
        self.pageSize = pageSize
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
        guard !isLoadingMore, hasMorePages else { return }
        currentPage += 1
        await fetch(mode: .loadMore)
    }

    func prefetchNextPageIfNeeded() async {
        guard !isLoadingMore, hasMorePages, state == .loaded else { return }
        currentPage += 1
        await fetch(mode: .prefetch)
    }

    func isSaved(_ article: Article) -> Bool {
        savedArticleIDs.contains(article.id)
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

    private func fetch(mode: FetchMode) async {
        let requestID = UUID()
        latestRequestID = requestID

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

        do {
            let bypassCache = mode == .pullToRefresh || mode == .retry
            async let fetchedResult = feedUseCase.execute(page: currentPage, pageSize: pageSize, bypassCache: bypassCache)
            async let savedIDs = readingListUseCase.savedArticleIDs()
            let result = try await (fetchedResult, savedIDs)

            guard latestRequestID == requestID else { return }

            if mode == .loadMore {
                appendNewArticles(result.0.items)
            } else {
                articles = result.0.items
            }

            hasMorePages = result.0.hasMorePages
            savedArticleIDs = result.1
            carouselSelection = min(carouselSelection, max(featuredArticles.count - 1, 0))
            resetLoadingState(mode: mode)
            state = articles.isEmpty ? .empty : .loaded
        } catch {
            resetLoadingState(mode: mode)
            if articles.isEmpty {
                state = .error(L10n.text("error.generic"))
            }
            ToastManager.shared.show(
                L10n.text("error.generic"),
                style: .error,
                duration: 5.0,
                action: ToastAction(title: L10n.text("retry.button")) { [weak self] in
                    Task { await self?.retry() }
                }
            )
        }
    }

    private func appendNewArticles(_ newItems: [Article]) {
        let existingIDs = Set(articles.map(\.id))
        let uniqueNewItems = newItems.filter { !existingIDs.contains($0.id) }
        articles.append(contentsOf: uniqueNewItems)
    }

    private func resetLoadingState(mode: FetchMode) {
        switch mode {
        case .loadMore: isLoadingMore = false
        case .pullToRefresh: isRefreshing = false
        default: break
        }
    }
}

private enum FetchMode {
    case initial, pullToRefresh, retry, automatic, loadMore, prefetch
}
