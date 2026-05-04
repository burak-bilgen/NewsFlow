import Foundation
import Combine

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
    @Published var selectedCategories: Set<String> = [] {
        didSet {
            applyFilters()
        }
    }

    private let repository: SourcesRepositoryProtocol
    private var latestRequestID = UUID()

    init(repository: SourcesRepositoryProtocol) {
        self.repository = repository
    }

    func load() async {
        guard state != .loading else { return }
        let requestID = UUID()
        latestRequestID = requestID
        state = .loading

        do {
            let fetchedSources = try await repository.fetchSources()
            guard latestRequestID == requestID else { return }

            sources = fetchedSources
            categories = SourceFilterService.categories(from: fetchedSources)
            applyFilters()
            state = visibleSources.isEmpty ? .empty : .loaded
        } catch let error as NewsAPIError {
            guard latestRequestID == requestID else { return }
            state = .error(error.userMessage)
        } catch {
            guard latestRequestID == requestID else { return }
            state = .error(L10n.text("error.generic"))
        }
    }

    func retry() async {
        await load()
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

    private func applyFilters() {
        visibleSources = SourceFilterService.filter(sources: sources, selectedCategories: selectedCategories)
        if case .loaded = state, visibleSources.isEmpty {
            state = .empty
        } else if case .empty = state, !visibleSources.isEmpty {
            state = .loaded
        }
    }
}
