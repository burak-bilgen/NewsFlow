import Combine
import Foundation

// MARK: - SourcesViewModel

/// Manages the state and business logic for the news sources screen.
/// Groups sources by category to support a Netflix-style horizontal browsing experience.
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

    /// Sources grouped by category for the Netflix-style horizontal rows.
    var groupedSources: [(category: String, sources: [NewsSource])] {
        let grouped = Dictionary(grouping: visibleSources) { $0.category }
        return categories
            .filter { selectedCategories.isEmpty || selectedCategories.contains($0) }
            .compactMap { category -> (String, [NewsSource])? in
                let sources = grouped[category] ?? []
                return sources.isEmpty ? nil : (category, sources)
            }
    }

    private let repository: SourcesRepositoryProtocol
    private let filterService: SourceFiltering
    private var latestRequestID = UUID()

    init(
        repository: SourcesRepositoryProtocol,
        filterService: SourceFiltering = SourceFilterService()
    ) {
        self.repository = repository
        self.filterService = filterService
    }

    /// Loads sources from the repository. Only runs if not already loading.
    func load() async {
        guard state != .loading else { return }
        await performFetch(showLoading: true)
    }

    /// Retries loading sources. Resets to loading state.
    func retry() async {
        await load()
    }

    /// Pull-to-refresh support. Silently refreshes without showing full-screen loading.
    func refresh() async {
        await performFetch(showLoading: false)
    }

    /// Toggles a category filter.
    func toggleCategory(_ category: String) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }

    /// Returns a human-readable localized name for a raw category key.
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
            let fetchedSources = try await repository.fetchSources()
            guard latestRequestID == requestID else { return }

            sources = fetchedSources
            categories = filterService.categories(from: fetchedSources)
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
        visibleSources = filterService.filter(sources: sources, selectedCategories: selectedCategories)
        if case .loaded = state, visibleSources.isEmpty {
            state = .empty
        } else if case .empty = state, !visibleSources.isEmpty {
            state = .loaded
        }
    }
}
