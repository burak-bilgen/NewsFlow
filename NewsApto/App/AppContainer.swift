import Combine
import Foundation

@MainActor
final class AppContainer: ObservableObject {
    private let fetchSourcesUseCase: FetchSourcesUseCaseProtocol
    private let fetchArticlesUseCaseFactory: (NewsSource) -> FetchArticlesUseCaseProtocol
    private let readingListUseCase: ManageReadingListUseCaseProtocol
    let aggregatorService: NewsAggregatorService

    init(
        fetchSourcesUseCase: FetchSourcesUseCaseProtocol,
        fetchArticlesUseCaseFactory: @escaping (NewsSource) -> FetchArticlesUseCaseProtocol,
        readingListUseCase: ManageReadingListUseCaseProtocol,
        aggregatorService: NewsAggregatorService
    ) {
        self.fetchSourcesUseCase = fetchSourcesUseCase
        self.fetchArticlesUseCaseFactory = fetchArticlesUseCaseFactory
        self.readingListUseCase = readingListUseCase
        self.aggregatorService = aggregatorService
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
            let mockArticlesRepo = MockArticlesRepository(articlesBySource: NewsFixture.articlesBySource)
            let aggregator = NewsAggregatorService(
                newsAPIRepository: mockArticlesRepo,
                guardianClient: MockGuardianClient(),
                nytClient: MockNYTClient()
            )
            return AppContainer(
                fetchSourcesUseCase: FetchSourcesUseCase(repository: sourcesRepo),
                fetchArticlesUseCaseFactory: { _ in
                    FetchArticlesUseCase(repository: mockArticlesRepo)
                },
                readingListUseCase: readingListUseCase,
                aggregatorService: aggregator
            )
        }
        #endif

        let requestBuilder = NewsAPIRequestBuilder()
        let baseClient = NewsAPIClient(requestBuilder: requestBuilder)
        let client: NewsAPIClientProtocol = RetryingNewsAPIClientDecorator(client: baseClient)
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

        let aggregator = NewsAggregatorService(
            newsAPIRepository: cachedNewsAPIArticles,
            guardianClient: guardianClient,
            nytClient: nytClient
        )

        return AppContainer(
            fetchSourcesUseCase: FetchSourcesUseCase(repository: sourcesRepo),
            fetchArticlesUseCaseFactory: { _ in
                FetchArticlesUseCase(repository: articlesRepo)
            },
            readingListUseCase: ManageReadingListUseCase(repository: readingListRepo),
            aggregatorService: aggregator
        )
    }

    func makeSourcesViewModel() -> SourcesViewModel {
        SourcesViewModel(fetchUseCase: fetchSourcesUseCase)
    }

    func makeFeedViewModel() -> FeedViewModel {
        FeedViewModel(
            aggregator: aggregatorService,
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
