import Combine
import Foundation

@MainActor
final class SourcesViewModel: ObservableObject {
    enum State: Equatable {
        case idle, loading, loaded, empty
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var sources: [NewsSource] = []
    @Published private(set) var categories: [String] = []
    @Published private(set) var visibleSources: [NewsSource] = []
    @Published private(set) var isRefreshing = false
    @Published var selectedCategories: Set<String> = [] {
        didSet { applyFilters() }
    }

    var groupedSources: [(category: String, sources: [NewsSource])] {
        FilterSourcesUseCase().groupByCategory(visibleSources, categories: categories, selectedCategories: selectedCategories)
    }

    private let fetchUseCase: FetchSourcesUseCaseProtocol
    private var latestRequestID = UUID()

    init(fetchUseCase: FetchSourcesUseCaseProtocol) {
        self.fetchUseCase = fetchUseCase
    }

    func load() async {
        guard state != .loading else { return }
        await performFetch(showLoading: true)
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

    private func performFetch(showLoading: Bool) async {
        let requestID = UUID()
        latestRequestID = requestID
        if showLoading { state = .loading } else { isRefreshing = true }

        do {
            let fetchedSources = try await fetchUseCase.execute(bypassCache: !showLoading)
            guard latestRequestID == requestID else { return }
            sources = fetchedSources
            categories = FilterSourcesUseCase().extractCategories(from: fetchedSources)
            applyFilters()
            if !showLoading { isRefreshing = false }
            state = visibleSources.isEmpty ? .empty : .loaded
        } catch {
            guard latestRequestID == requestID else { return }
            if !showLoading { isRefreshing = false }
            state = .empty
        }
    }

    private func applyFilters() {
        visibleSources = FilterSourcesUseCase().execute(sources: sources, selectedCategories: selectedCategories)
        if case .loaded = state, visibleSources.isEmpty { state = .empty }
        else if case .empty = state, !visibleSources.isEmpty { state = .loaded }
    }
}
