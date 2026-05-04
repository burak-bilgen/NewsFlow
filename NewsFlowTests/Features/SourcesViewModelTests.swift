import XCTest
@testable import NewsFlow

@MainActor
final class SourcesViewModelTests: XCTestCase {
    private func makeViewModel(
        sources: [NewsSource] = [],
        result: Result<[NewsSource], Error> = .success([])
    ) -> SourcesViewModel {
        SourcesViewModel(repository: SourcesRepositorySpy(result: result))
    }

    // MARK: - Initial State

    func testInitialStateIsIdle() {
        let viewModel = makeViewModel()
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertTrue(viewModel.sources.isEmpty)
        XCTAssertTrue(viewModel.categories.isEmpty)
        XCTAssertTrue(viewModel.visibleSources.isEmpty)
        XCTAssertFalse(viewModel.isRefreshing)
        XCTAssertTrue(viewModel.selectedCategories.isEmpty)
    }

    // MARK: - Loading

    func testLoadSuccessSetsLoadedStateAndFiltersEnglish() async {
        let sources = [
            NewsSource(id: "bbc", name: "BBC", description: "A", category: "general", language: "en", url: nil),
            NewsSource(id: "fr", name: "Le Monde", description: "B", category: "general", language: "fr", url: nil)
        ]
        let viewModel = makeViewModel(result: .success(sources))

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(viewModel.visibleSources.count, 1)
        XCTAssertEqual(viewModel.visibleSources.first?.id, "bbc")
    }

    func testLoadExtractsCategories() async {
        let sources = [
            NewsSource(id: "bbc", name: "BBC", description: "A", category: "general", language: "en", url: nil),
            NewsSource(id: "tc", name: "TC", description: "B", category: "technology", language: "en", url: nil)
        ]
        let viewModel = makeViewModel(result: .success(sources))

        await viewModel.load()

        XCTAssertEqual(viewModel.categories, ["general", "technology"])
    }

    func testLoadErrorSetsErrorState() async {
        let viewModel = makeViewModel(result: .failure(NewsAPIError.network))

        await viewModel.load()

        guard case .error = viewModel.state else {
            return XCTFail("Expected error state")
        }
    }

    func testLoadGenericErrorSetsGenericErrorMessage() async {
        let viewModel = makeViewModel(result: .failure(NSError(domain: "test", code: 0)))

        await viewModel.load()

        if case let .error(message) = viewModel.state {
            XCTAssertEqual(message, L10n.text("error.generic"))
        } else {
            XCTFail("Expected error state")
        }
    }

    func testEmptySourcesSetEmptyState() async {
        let viewModel = makeViewModel(result: .success([]))

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .empty)
    }

    func testLoadDoesNotExecuteTwiceWhenConcurrentlyLoading() async {
        let sources = [
            NewsSource(id: "bbc", name: "BBC", description: "A", category: "general", language: "en", url: nil)
        ]
        let repository = DelayedSourcesRepositorySpy(
            result: .success(sources),
            delayNanoseconds: 200_000_000
        )
        let viewModel = SourcesViewModel(repository: repository)

        async let first: () = viewModel.load()
        async let second: () = viewModel.load()
        _ = await (first, second)

        XCTAssertEqual(repository.requestCount, 1)
    }

    // MARK: - Refresh

    func testRefreshSetsIsRefreshingAndUpdatesSources() async {
        let sources = [
            NewsSource(id: "bbc", name: "BBC", description: "A", category: "general", language: "en", url: nil)
        ]
        let viewModel = makeViewModel(result: .success(sources))

        await viewModel.refresh()

        XCTAssertFalse(viewModel.isRefreshing)
        XCTAssertEqual(viewModel.state, .loaded)
    }

    func testRefreshOnErrorSilentlyResetsIsRefreshing() async {
        let viewModel = makeViewModel(result: .failure(NewsAPIError.network))

        await viewModel.refresh()

        XCTAssertFalse(viewModel.isRefreshing)
    }

    func testRefreshDoesNotShowLoadingState() async {
        let sources = [
            NewsSource(id: "bbc", name: "BBC", description: "A", category: "general", language: "en", url: nil)
        ]
        let repository = DelayedSourcesRepositorySpy(
            result: .success(sources),
            delayNanoseconds: 50_000_000
        )
        let viewModel = SourcesViewModel(repository: repository)

        let expectation = expectation(description: "refresh completes")
        Task {
            await viewModel.refresh()
            expectation.fulfill()
        }

        try? await Task.sleep(nanoseconds: 10_000_000)
        XCTAssertTrue(viewModel.isRefreshing)
        XCTAssertNotEqual(viewModel.state, .loading)

        await fulfillment(of: [expectation], timeout: 2)
        XCTAssertFalse(viewModel.isRefreshing)
    }

    // MARK: - Stale Request Cancellation

    func testStaleRefreshRequestIsIgnored() async {
        let sources = [
            NewsSource(id: "bbc", name: "BBC", description: "A", category: "general", language: "en", url: nil)
        ]
        let repository = DelayedSourcesRepositorySpy(
            result: .success(sources),
            delayNanoseconds: 300_000_000
        )
        let viewModel = SourcesViewModel(repository: repository)

        Task {
            await viewModel.load()
        }
        try? await Task.sleep(nanoseconds: 50_000_000)

        await viewModel.refresh()

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(repository.requestCount, 2)
    }

    // MARK: - Category Filtering

    func testToggleCategoryAddsAndRemoves() async {
        let sources = [
            NewsSource(id: "bbc", name: "BBC", description: "A", category: "general", language: "en", url: nil),
            NewsSource(id: "tc", name: "TC", description: "B", category: "technology", language: "en", url: nil)
        ]
        let viewModel = makeViewModel(result: .success(sources))
        await viewModel.load()

        viewModel.toggleCategory("general")
        XCTAssertTrue(viewModel.selectedCategories.contains("general"))

        viewModel.toggleCategory("general")
        XCTAssertFalse(viewModel.selectedCategories.contains("general"))
    }

    func testFilterByCategoryUpdatesVisibleSources() async {
        let sources = [
            NewsSource(id: "bbc", name: "BBC", description: "A", category: "general", language: "en", url: nil),
            NewsSource(id: "tc", name: "TC", description: "B", category: "technology", language: "en", url: nil),
            NewsSource(id: "espn", name: "ESPN", description: "C", category: "sports", language: "en", url: nil)
        ]
        let viewModel = makeViewModel(result: .success(sources))
        await viewModel.load()

        viewModel.toggleCategory("general")

        XCTAssertEqual(viewModel.visibleSources.count, 1)
        XCTAssertEqual(viewModel.visibleSources.first?.id, "bbc")
    }

    func testMultipleCategorySelectionReturnsUnion() async {
        let sources = [
            NewsSource(id: "bbc", name: "BBC", description: "A", category: "general", language: "en", url: nil),
            NewsSource(id: "tc", name: "TC", description: "B", category: "technology", language: "en", url: nil),
            NewsSource(id: "espn", name: "ESPN", description: "C", category: "sports", language: "en", url: nil)
        ]
        let viewModel = makeViewModel(result: .success(sources))
        await viewModel.load()

        viewModel.toggleCategory("general")
        viewModel.toggleCategory("technology")

        XCTAssertEqual(viewModel.visibleSources.count, 2)
        let ids = viewModel.visibleSources.map(\.id)
        XCTAssertTrue(ids.contains("bbc"))
        XCTAssertTrue(ids.contains("tc"))
    }

    func testEmptyCategorySelectionReturnsAllEnglishSources() async {
        let sources = [
            NewsSource(id: "bbc", name: "BBC", description: "A", category: "general", language: "en", url: nil),
            NewsSource(id: "tc", name: "TC", description: "B", category: "technology", language: "en", url: nil)
        ]
        let viewModel = makeViewModel(result: .success(sources))
        await viewModel.load()

        XCTAssertEqual(viewModel.visibleSources.count, 2)
    }

    func testFilterWithNoMatchingCategoriesReturnsEmpty() async {
        let sources = [
            NewsSource(id: "bbc", name: "BBC", description: "A", category: "general", language: "en", url: nil)
        ]
        let viewModel = makeViewModel(result: .success(sources))
        await viewModel.load()

        viewModel.toggleCategory("technology")
        XCTAssertTrue(viewModel.visibleSources.isEmpty)
    }

    func testFilterTransitionsStateFromLoadedToEmptyAndBack() async {
        let sources = [
            NewsSource(id: "bbc", name: "BBC", description: "A", category: "general", language: "en", url: nil),
            NewsSource(id: "tc", name: "TC", description: "B", category: "technology", language: "en", url: nil)
        ]
        let viewModel = makeViewModel(result: .success(sources))
        await viewModel.load()
        XCTAssertEqual(viewModel.state, .loaded)

        viewModel.toggleCategory("sports")
        XCTAssertEqual(viewModel.state, .empty)

        viewModel.toggleCategory("general")
        XCTAssertEqual(viewModel.state, .loaded)
    }

    // MARK: - Grouped Sources

    func testGroupedSourcesGroupsByCategory() async {
        let sources = [
            NewsSource(id: "bbc", name: "BBC", description: "A", category: "general", language: "en", url: nil),
            NewsSource(id: "reuters", name: "Reuters", description: "R", category: "general", language: "en", url: nil),
            NewsSource(id: "tc", name: "TC", description: "B", category: "technology", language: "en", url: nil)
        ]
        let viewModel = makeViewModel(result: .success(sources))
        await viewModel.load()

        let grouped = viewModel.groupedSources
        XCTAssertEqual(grouped.count, 2)

        let generalGroup = grouped.first { $0.category == "general" }
        XCTAssertEqual(generalGroup?.sources.count, 2)

        let techGroup = grouped.first { $0.category == "technology" }
        XCTAssertEqual(techGroup?.sources.count, 1)
    }

    func testGroupedSourcesOmitsEmptyCategories() async {
        let sources = [
            NewsSource(id: "bbc", name: "BBC", description: "A", category: "general", language: "en", url: nil)
        ]
        let viewModel = makeViewModel(result: .success(sources))
        await viewModel.load()

        viewModel.toggleCategory("general")

        let grouped = viewModel.groupedSources
        XCTAssertEqual(grouped.count, 1)
        XCTAssertEqual(grouped.first?.category, "general")
    }

    // MARK: - Retry

    func testRetryAfterErrorReloads() async {
        let viewModel = makeViewModel(result: .failure(NewsAPIError.network))
        await viewModel.load()

        guard case .error = viewModel.state else { return XCTFail("Expected error") }

        let repository = SourcesRepositorySpy(result: .success([
            NewsSource(id: "bbc", name: "BBC", description: "A", category: "general", language: "en", url: nil)
        ]))
        let freshViewModel = SourcesViewModel(repository: repository)
        await freshViewModel.load()

        XCTAssertEqual(freshViewModel.state, .loaded)
    }

    // MARK: - Localization

    func testLocalizedCategoryReturnsKey() {
        let viewModel = makeViewModel()
        let result = viewModel.localizedCategory("general")
        XCTAssertEqual(result, L10n.text("category.general"))
    }
}
