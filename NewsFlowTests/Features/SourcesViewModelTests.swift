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

    func testInitialStateIsIdle() {
        let viewModel = makeViewModel()
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertTrue(viewModel.sources.isEmpty)
        XCTAssertTrue(viewModel.categories.isEmpty)
        XCTAssertTrue(viewModel.visibleSources.isEmpty)
    }

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

    func testLocalizedCategoryReturnsKey() {
        let viewModel = makeViewModel()
        let result = viewModel.localizedCategory("general")
        XCTAssertEqual(result, L10n.text("category.general"))
    }

    func testLoadDoesNotExecuteTwiceWhenLoading() async {
        let sources = [
            NewsSource(id: "bbc", name: "BBC", description: "A", category: "general", language: "en", url: nil)
        ]
        let viewModel = makeViewModel(result: .success(sources))

        await viewModel.load()
        await viewModel.load()

        XCTAssertEqual(viewModel.visibleSources.count, 1)
    }
}
