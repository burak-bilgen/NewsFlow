import Foundation

// MARK: - Filter Sources Use Case

protocol FilterSourcesUseCaseProtocol {
    func execute(sources: [NewsSource], selectedCategories: Set<String>) -> [NewsSource]
    func extractCategories(from sources: [NewsSource]) -> [String]
    func groupByCategory(
        _ sources: [NewsSource],
        categories: [String],
        selectedCategories: Set<String>
    ) -> [(category: String, sources: [NewsSource])]
}

final class FilterSourcesUseCase: FilterSourcesUseCaseProtocol {
    private let filterService: SourceFiltering

    init(filterService: SourceFiltering = SourceFilterService()) {
        self.filterService = filterService
    }

    func execute(sources: [NewsSource], selectedCategories: Set<String>) -> [NewsSource] {
        filterService.filter(sources: sources, selectedCategories: selectedCategories)
    }

    func extractCategories(from sources: [NewsSource]) -> [String] {
        filterService.categories(from: sources)
    }

    func groupByCategory(
        _ sources: [NewsSource],
        categories: [String],
        selectedCategories: Set<String>
    ) -> [(category: String, sources: [NewsSource])] {
        let grouped = Dictionary(grouping: sources) { $0.category }
        return categories
            .filter { selectedCategories.isEmpty || selectedCategories.contains($0) }
            .compactMap { category -> (String, [NewsSource])? in
                let list = grouped[category] ?? []
                return list.isEmpty ? nil : (category, list)
            }
    }
}
