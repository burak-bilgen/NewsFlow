import Foundation

enum SourceFilterService {
    static func englishSources(from sources: [NewsSource]) -> [NewsSource] {
        sources
            .filter { $0.language.lowercased() == "en" }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    static func categories(from sources: [NewsSource]) -> [String] {
        Array(Set(englishSources(from: sources).map(\.category)))
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    static func filter(sources: [NewsSource], selectedCategories: Set<String>) -> [NewsSource] {
        let english = englishSources(from: sources)
        guard !selectedCategories.isEmpty else { return english }
        return english.filter { selectedCategories.contains($0.category) }
    }
}
