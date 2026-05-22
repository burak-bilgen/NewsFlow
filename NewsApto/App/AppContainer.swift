import Foundation

@MainActor
final class AppContainer: ObservableObject {
    private let readingListUseCase: ManageReadingListUseCaseProtocol
    let aggregatorService: NewsAggregatorService

    init(
        readingListUseCase: ManageReadingListUseCaseProtocol,
        aggregatorService: NewsAggregatorService
    ) {
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
            let mockArticlesRepo = MockArticlesRepository(articlesBySource: NewsFixture.articlesBySource)
            let aggregator = NewsAggregatorService(
                newsAPIRepository: mockArticlesRepo,
                guardianClient: MockGuardianClient(),
                nytClient: MockNYTClient(),
                gnewsClient: nil,
                newsDataClient: nil,
                hackerNewsClient: nil
            )
            return AppContainer(
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

        let newsAPIArticlesRepo = NewsAPIArticlesRepository(client: client)
        let cachedNewsAPIArticles = CachedArticlesRepository(
            remoteRepository: newsAPIArticlesRepo,
            store: store
        )
        let guardianClient = GuardianClient()
        let nytClient = NYTClient()
        let readingListRepo: ReadingListRepositoryProtocol = CoreDataReadingListRepository()

        let aggregator = NewsAggregatorService(
            newsAPIRepository: cachedNewsAPIArticles,
            guardianClient: guardianClient,
            nytClient: nytClient,
            gnewsClient: GNewsClient(),
            newsDataClient: NewsDataClient(),
            hackerNewsClient: HackerNewsClient()
        )

        return AppContainer(
            readingListUseCase: ManageReadingListUseCase(repository: readingListRepo),
            aggregatorService: aggregator
        )
    }

    func makeFeedViewModel() -> FeedViewModel {
        FeedViewModel(
            aggregator: aggregatorService,
            readingListUseCase: readingListUseCase
        )
    }

    func makeReadingListViewModel() -> ReadingListViewModel {
        ReadingListViewModel(useCase: readingListUseCase)
    }
}
