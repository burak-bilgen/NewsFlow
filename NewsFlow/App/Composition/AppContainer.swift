import Foundation
import Combine

@MainActor
final class AppContainer: ObservableObject {
    private let sourcesRepository: SourcesRepositoryProtocol
    private let articlesRepository: ArticlesRepositoryProtocol
    private let readingListRepository: ReadingListRepositoryProtocol
    private let errorSimulator: ArticleRequestErrorSimulating

    init(
        sourcesRepository: SourcesRepositoryProtocol,
        articlesRepository: ArticlesRepositoryProtocol,
        readingListRepository: ReadingListRepositoryProtocol,
        errorSimulator: ArticleRequestErrorSimulating
    ) {
        self.sourcesRepository = sourcesRepository
        self.articlesRepository = articlesRepository
        self.readingListRepository = readingListRepository
        self.errorSimulator = errorSimulator
    }

    static func make() -> AppContainer {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("UITest.ResetState") {
            UserDefaults.standard.removeObject(forKey: UserDefaultsReadingListRepository.storageKey)
        }

        if ProcessInfo.processInfo.arguments.contains("UITest.MockNews") {
            let readingListRepository = InMemoryReadingListRepository()
            return AppContainer(
                sourcesRepository: MockSourcesRepository(sources: NewsFixture.sources),
                articlesRepository: MockArticlesRepository(articlesBySource: NewsFixture.articlesBySource),
                readingListRepository: readingListRepository,
                errorSimulator: EveryThirdRequestErrorSimulator()
            )
        }
        #endif

        let requestBuilder = NewsAPIRequestBuilder()
        let client = NewsAPIClient(requestBuilder: requestBuilder)
        return AppContainer(
            sourcesRepository: NewsAPISourcesRepository(client: client),
            articlesRepository: NewsAPIArticlesRepository(client: client),
            readingListRepository: UserDefaultsReadingListRepository(),
            errorSimulator: EveryThirdRequestErrorSimulator()
        )
    }

    func makeSourcesViewModel() -> SourcesViewModel {
        SourcesViewModel(repository: sourcesRepository)
    }

    func makeArticlesViewModel(source: NewsSource) -> ArticlesViewModel {
        ArticlesViewModel(
            source: source,
            articlesRepository: articlesRepository,
            readingListRepository: readingListRepository,
            errorSimulator: errorSimulator
        )
    }
}
