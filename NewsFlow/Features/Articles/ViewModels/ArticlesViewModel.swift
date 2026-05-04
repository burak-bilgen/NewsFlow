import Foundation
import Combine

@MainActor
final class ArticlesViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case empty
        case error(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var articles: [Article] = []

    let source: NewsSource

    private let articlesRepository: ArticlesRepositoryProtocol
    private var latestRequestID = UUID()

    init(
        source: NewsSource,
        articlesRepository: ArticlesRepositoryProtocol
    ) {
        self.source = source
        self.articlesRepository = articlesRepository
    }

    func load() async {
        guard state != .loading else { return }
        let requestID = UUID()
        latestRequestID = requestID
        state = .loading

        do {
            let fetchedArticles = try await articlesRepository.fetchArticles(sourceID: source.id)
            guard latestRequestID == requestID else { return }

            articles = ArticleSorter.newestFirst(fetchedArticles)
            state = articles.isEmpty ? .empty : .loaded
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
}
