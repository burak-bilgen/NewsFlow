import Combine
import Foundation

@MainActor
final class AppContainer: ObservableObject {
    private let fetchSourcesUseCase: FetchSourcesUseCaseProtocol
    private let fetchArticlesUseCaseFactory: (NewsSource) -> FetchArticlesUseCaseProtocol
    private let readingListUseCase: ManageReadingListUseCaseProtocol

    init(
        fetchSourcesUseCase: FetchSourcesUseCaseProtocol,
        fetchArticlesUseCaseFactory: @escaping (NewsSource) -> FetchArticlesUseCaseProtocol,
        readingListUseCase: ManageReadingListUseCaseProtocol
    ) {
        self.fetchSourcesUseCase = fetchSourcesUseCase
        self.fetchArticlesUseCaseFactory = fetchArticlesUseCaseFactory
        self.readingListUseCase = readingListUseCase
    }

    static func make() -> AppContainer {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("UITest.ResetState") {
            UserDefaults.standard.removeObject(forKey: UserDefaultsReadingListRepository.storageKey)
        }

        if ProcessInfo.processInfo.arguments.contains("UITest.MockNews") {
            let readingListRepo = InMemoryReadingListRepository()
            let readingListUseCase = ManageReadingListUseCase(repository: readingListRepo)
            let sourcesRepo = MockSourcesRepository(sources: NewsFixture.sources)
            let articlesRepo = MockArticlesRepository(articlesBySource: NewsFixture.articlesBySource)
            return AppContainer(
                fetchSourcesUseCase: FetchSourcesUseCase(repository: sourcesRepo),
                fetchArticlesUseCaseFactory: { _ in
                    FetchArticlesUseCase(repository: articlesRepo)
                },
                readingListUseCase: readingListUseCase
            )
        }
        #endif

        let requestBuilder = NewsAPIRequestBuilder()
        let baseClient = NewsAPIClient(requestBuilder: requestBuilder)
        let retryingClient = RetryingNewsAPIClientDecorator(client: baseClient)
        let client = SimulatedNetworkErrorClientDecorator(client: retryingClient)
        let store: PersistentStore
        do {
            store = try FilePersistentStore()
        } catch {
            store = InMemoryPersistentStore()
        }

        let sourcesRepo = CachedSourcesRepository(
            remoteRepository: NewsAPISourcesRepository(client: client),
            store: store
        )
        let articlesRepo = CachedArticlesRepository(
            remoteRepository: NewsAPIArticlesRepository(client: client),
            store: store
        )
        let readingListRepo: ReadingListRepositoryProtocol = CoreDataReadingListRepository()

        CrashReporter.shared.recordBreadcrumb(
            "AppContainer initialized",
            category: "Lifecycle",
            metadata: ["store": String(describing: type(of: store))]
        )

        return AppContainer(
            fetchSourcesUseCase: FetchSourcesUseCase(repository: sourcesRepo),
            fetchArticlesUseCaseFactory: { _ in
                FetchArticlesUseCase(repository: articlesRepo)
            },
            readingListUseCase: ManageReadingListUseCase(repository: readingListRepo)
        )
    }

    func makeSourcesViewModel() -> SourcesViewModel {
        SourcesViewModel(fetchUseCase: fetchSourcesUseCase)
    }

    func makeArticlesViewModel(source: NewsSource) -> ArticlesViewModel {
        ArticlesViewModel(
            source: source,
            fetchUseCase: fetchArticlesUseCaseFactory(source),
            readingListUseCase: readingListUseCase
        )
    }
}
