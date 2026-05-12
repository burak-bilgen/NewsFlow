import Combine
import Foundation

@MainActor
final class AppContainer: ObservableObject {
    private let fetchSourcesUseCase: FetchSourcesUseCaseProtocol
    private let fetchArticlesUseCaseFactory: (NewsSource) -> FetchArticlesUseCaseProtocol
    private let feedUseCase: FetchFeedUseCaseProtocol
    private let readingListUseCase: ManageReadingListUseCaseProtocol

    init(
        fetchSourcesUseCase: FetchSourcesUseCaseProtocol,
        fetchArticlesUseCaseFactory: @escaping (NewsSource) -> FetchArticlesUseCaseProtocol,
        feedUseCase: FetchFeedUseCaseProtocol,
        readingListUseCase: ManageReadingListUseCaseProtocol
    ) {
        self.fetchSourcesUseCase = fetchSourcesUseCase
        self.fetchArticlesUseCaseFactory = fetchArticlesUseCaseFactory
        self.feedUseCase = feedUseCase
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
            let feedUseCase = FetchFeedUseCase(repository: articlesRepo)
            return AppContainer(
                fetchSourcesUseCase: FetchSourcesUseCase(repository: sourcesRepo),
                fetchArticlesUseCaseFactory: { _ in
                    FetchArticlesUseCase(repository: articlesRepo)
                },
                feedUseCase: feedUseCase,
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
        let newsAPIArticlesRepo = NewsAPIArticlesRepository(client: client)
        let cachedNewsAPIArticles = CachedArticlesRepository(
            remoteRepository: newsAPIArticlesRepo,
            store: store
        )
        let guardianClient = GuardianClient()
        let nytClient = NYTClient()
        let articlesRepo = AggregateArticlesRepository(
            newsAPIRepository: cachedNewsAPIArticles,
            guardianClient: guardianClient,
            nytClient: nytClient
        )
            let readingListRepo: ReadingListRepositoryProtocol = CoreDataReadingListRepository()

        let feedUseCase = FetchFeedUseCase(repository: articlesRepo)

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
            feedUseCase: feedUseCase,
            readingListUseCase: ManageReadingListUseCase(repository: readingListRepo)
        )
    }

    func makeSourcesViewModel() -> SourcesViewModel {
        SourcesViewModel(fetchUseCase: fetchSourcesUseCase)
    }

    func makeFeedViewModel() -> FeedViewModel {
        FeedViewModel(
            feedUseCase: feedUseCase,
            readingListUseCase: readingListUseCase
        )
    }

    func makeArticlesViewModel(source: NewsSource) -> ArticlesViewModel {
        ArticlesViewModel(
            source: source,
            fetchUseCase: fetchArticlesUseCaseFactory(source),
            readingListUseCase: readingListUseCase
        )
    }

    func makeReadingListViewModel() -> ReadingListViewModel {
        ReadingListViewModel(useCase: readingListUseCase)
    }
}
