import Foundation

actor UserDefaultsReadingListRepository: ReadingListRepositoryProtocol {
    static let storageKey = "newsflow.readingList.articles"

    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func savedArticleIDs() async -> Set<String> {
        Set(loadArticles().map(\.id))
    }

    func isSaved(articleID: String) async -> Bool {
        loadArticles().contains { $0.id == articleID }
    }

    func add(_ article: Article) async throws {
        var articles = loadArticles()
        guard !articles.contains(where: { $0.id == article.id }) else { return }
        articles.append(article)
        try save(articles)
    }

    func remove(articleID: String) async throws {
        let articles = loadArticles().filter { $0.id != articleID }
        try save(articles)
    }

    private func loadArticles() -> [Article] {
        guard let data = userDefaults.data(forKey: Self.storageKey) else { return [] }
        return (try? decoder.decode([Article].self, from: data)) ?? []
    }

    private func save(_ articles: [Article]) throws {
        let data = try encoder.encode(articles)
        userDefaults.set(data, forKey: Self.storageKey)
    }
}
