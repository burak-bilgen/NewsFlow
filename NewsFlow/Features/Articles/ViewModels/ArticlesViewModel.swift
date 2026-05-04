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
    @Published private(set) var savedArticleIDs: Set<String> = []
    @Published var carouselSelection = 0
    @Published var warningMessage: String?

    let source: NewsSource

    private let articlesRepository: ArticlesRepositoryProtocol
    private let readingListRepository: ReadingListRepositoryProtocol
    private var latestRequestID = UUID()

    init(
        source: NewsSource,
        articlesRepository: ArticlesRepositoryProtocol,
        readingListRepository: ReadingListRepositoryProtocol
    ) {
        self.source = source
        self.articlesRepository = articlesRepository
        self.readingListRepository = readingListRepository
    }

    var featuredArticles: [Article] {
        Array(articles.prefix(3))
    }

    var listArticles: [Article] {
        Array(articles.dropFirst(3))
    }

    func load() async {
        guard state != .loading else { return }
        let requestID = UUID()
        latestRequestID = requestID
        state = .loading

        do {
            async let fetchedArticles = articlesRepository.fetchArticles(sourceID: source.id)
            async let savedIDs = readingListRepository.savedArticleIDs()
            let result = try await (fetchedArticles, savedIDs)
            guard latestRequestID == requestID else { return }

            articles = ArticleSorter.newestFirst(result.0)
            savedArticleIDs = result.1
            carouselSelection = min(carouselSelection, max(featuredArticles.count - 1, 0))
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

    func isSaved(_ article: Article) -> Bool {
        savedArticleIDs.contains(article.id)
    }

    func toggleReadingList(for article: Article) async {
        do {
            let isSaved = try await readingListRepository.toggle(article)
            if isSaved {
                savedArticleIDs.insert(article.id)
            } else {
                savedArticleIDs.remove(article.id)
            }
        } catch {
            warningMessage = L10n.text("error.generic")
        }
    }
}
