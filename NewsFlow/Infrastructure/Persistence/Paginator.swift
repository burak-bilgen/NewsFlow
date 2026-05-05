import Foundation

// MARK: - Paginator State

/// Generic pagination state machine for any identifiable collection.
/// Supports first-load, load-more, refresh, and prefetch with deduplication.
enum PaginatorState<T: Identifiable>: Equatable {
    case idle
    case loading
    case loaded(items: [T], hasMore: Bool)
    case loadingMore(items: [T])
    case error(message: String, existingItems: [T]?)
    case empty
    case allLoaded(items: [T])

    static func == (lhs: PaginatorState<T>, rhs: PaginatorState<T>) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.empty, .empty): return true
        case let (.loaded(lItems, lHasMore), .loaded(rItems, rHasMore)):
            return lItems.map(\.id) == rItems.map(\.id) && lHasMore == rHasMore
        case let (.loadingMore(lItems), .loadingMore(rItems)):
            return lItems.map(\.id) == rItems.map(\.id)
        case let (.error(lMsg, lItems), .error(rMsg, rItems)):
            return lMsg == rMsg && lItems?.map(\.id) == rItems?.map(\.id)
        case let (.allLoaded(lItems), .allLoaded(rItems)):
            return lItems.map(\.id) == rItems.map(\.id)
        default: return false
        }
    }
}

// MARK: - Paginator

/// Professional generic paginator with deduplication, prefetch, and retry support.
///
/// Usage:
/// ```swift
/// let paginator = Paginator<Article>(pageSize: 20) { page, pageSize in
///     try await repository.fetchArticles(page: page, pageSize: pageSize)
/// }
/// let state = await paginator.loadFirst()
/// ```
@MainActor
final class Paginator<T: Identifiable> {
    typealias State = PaginatorState<T>
    typealias PageLoader = (Int, Int) async throws -> PaginatedResult<T>

    private(set) var state: State = .idle
    private(set) var items: [T] = []
    private var currentPage = 1
    private var isLoading = false
    private var isPrefetching = false
    private var hasMorePages = true
    private let pageSize: Int
    private let loadPage: PageLoader
    private var latestRequestID = UUID()

    var hasMore: Bool { hasMorePages }
    var isEmpty: Bool { items.isEmpty }
    var allItems: [T] { items }

    init(pageSize: Int, loadPage: @escaping PageLoader) {
        self.pageSize = pageSize
        self.loadPage = loadPage
    }

    // MARK: - Public API

    /// Load the first page. Resets internal state.
    func loadFirst() async -> State {
        guard !isLoading else { return state }
        reset()
        return await performLoad(page: 1, mode: .initial)
    }

    /// Refresh while keeping existing items visible.
    func refresh() async -> State {
        guard !isLoading else { return state }
        return await performLoad(page: 1, mode: .refresh)
    }

    /// Load the next page. Returns existing state if no more pages.
    func loadNext() async -> State {
        guard !isLoading, hasMorePages else { return state }
        currentPage += 1
        return await performLoad(page: currentPage, mode: .loadMore)
    }

    /// Silent prefetch — no UI state changes except appending items.
    func prefetch() async -> State {
        guard !isPrefetching, !isLoading, hasMorePages else { return state }
        isPrefetching = true
        defer { isPrefetching = false }
        currentPage += 1
        return await performLoad(page: currentPage, mode: .prefetch)
    }

    /// Retry after error. Loads page 1 if empty, otherwise retries current.
    func retry() async -> State {
        guard !isLoading else { return state }
        let page = items.isEmpty ? 1 : currentPage
        return await performLoad(page: page, mode: .retry)
    }

    // MARK: - Private

    private enum LoadMode {
        case initial
        case refresh
        case loadMore
        case prefetch
        case retry
    }

    private func performLoad(page: Int, mode: LoadMode) async -> State {
        let requestID = UUID()
        latestRequestID = requestID
        isLoading = true

        // Apply loading state
        switch mode {
        case .initial, .retry:
            state = .loading
        case .loadMore:
            state = .loadingMore(items: items)
        case .refresh, .prefetch:
            break
        }

        do {
            let result = try await loadPage(page, pageSize)

            // Stale request check
            guard latestRequestID == requestID else { return state }

            // Deduplicate
            let newItems = deduplicate(result.items)

            // Update items based on mode
            switch mode {
            case .loadMore, .prefetch:
                items.append(contentsOf: newItems)
            case .initial, .refresh, .retry:
                items = newItems
            }

            hasMorePages = result.hasMorePages
            currentPage = result.currentPage

            if items.isEmpty {
                state = .empty
            } else if !hasMorePages {
                state = .allLoaded(items: items)
            } else {
                state = .loaded(items: items, hasMore: hasMorePages)
            }

        } catch {
            guard latestRequestID == requestID else { return state }
            let message = (error as? NewsAPIError)?.userMessage ?? "Something went wrong"
            if items.isEmpty {
                state = .error(message: message, existingItems: nil)
            } else {
                state = .loaded(items: items, hasMore: hasMorePages)
                // For loadMore/prefetch, revert page increment
                if mode == .loadMore || mode == .prefetch {
                    currentPage = max(currentPage - 1, 1)
                }
            }
        }

        isLoading = false
        return state
    }

    private func deduplicate(_ newItems: [T]) -> [T] {
        let existingIDs = Set(items.map(\.id))
        return newItems.filter { !existingIDs.contains($0.id) }
    }

    private func reset() {
        items.removeAll()
        currentPage = 1
        hasMorePages = true
        latestRequestID = UUID()
    }
}
