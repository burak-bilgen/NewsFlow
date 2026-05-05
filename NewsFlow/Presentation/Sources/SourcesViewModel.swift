import Combine
import Foundation

// MARK: - SourcesViewModel

/// Manages presentation state for the news sources screen.
/// Business logic is delegated to Use Cases.
@MainActor
final class SourcesViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case empty
        case error(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var sources: [NewsSource] = []
    @Published private(set) var categories: [String] = []
    @Published private(set) var visibleSources: [NewsSource] = []
    @Published private(set) var isRefreshing = false
    @Published var selectedCategories: Set<String> = [] {
        didSet {
            applyFilters()
        }
    }

    var groupedSources: [(category: String, sources: [NewsSource])] {
        FilterSourcesUseCase().groupByCategory(
            visibleSources,
            categories: categories,
            selectedCategories: selectedCategories
        )
    }

    private let fetchUseCase: FetchSourcesUseCaseProtocol
    private let filterUseCase: FilterSourcesUseCaseProtocol
    private var latestRequestID = UUID()

    init(
        fetchUseCase: FetchSourcesUseCaseProtocol,
        filterUseCase: FilterSourcesUseCaseProtocol = FilterSourcesUseCase()
    ) {
        self.fetchUseCase = fetchUseCase
        self.filterUseCase = filterUseCase
    }

    func load() async {
        guard state != .loading else { return }
        await performFetch(showLoading: true)
    }

    func retry() async {
        await load()
    }

    func refresh() async {
        await performFetch(showLoading: false)
    }

    func toggleCategory(_ category: String) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }

    func localizedCategory(_ category: String) -> String {
        L10n.text("category.\(category)")
    }

    // MARK: - Private

    private func performFetch(showLoading: Bool) async {
        let requestID = UUID()
        latestRequestID = requestID

        if showLoading {
            state = .loading
        } else {
            isRefreshing = true
        }

        do {
            let fetchedSources = try await fetchUseCase.execute()
            guard latestRequestID == requestID else { return }

            sources = fetchedSources
            categories = filterUseCase.extractCategories(from: fetchedSources)
            applyFilters()

            if !showLoading {
                isRefreshing = false
            }
            state = visibleSources.isEmpty ? .empty : .loaded
        } catch let error as NewsAPIError {
            guard latestRequestID == requestID else { return }
            if !showLoading {
                isRefreshing = false
            }
            state = .error(error.userMessage)
        } catch {
            guard latestRequestID == requestID else { return }
            if !showLoading {
                isRefreshing = false
            }
            state = .error(L10n.text("error.generic"))
        }
    }

    private func applyFilters() {
        visibleSources = filterUseCase.execute(sources: sources, selectedCategories: selectedCategories)
        if case .loaded = state, visibleSources.isEmpty {
            state = .empty
        } else if case .empty = state, !visibleSources.isEmpty {
            state = .loaded
        }
    }
}
