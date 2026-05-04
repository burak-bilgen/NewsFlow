import Foundation

protocol ReadingListRepositoryProtocol {
    func savedArticleIDs() async -> Set<String>
    func isSaved(articleID: String) async -> Bool
    func add(_ article: Article) async throws
    func remove(articleID: String) async throws
    func toggle(_ article: Article) async throws -> Bool
}

extension ReadingListRepositoryProtocol {
    func toggle(_ article: Article) async throws -> Bool {
        if await isSaved(articleID: article.id) {
            try await remove(articleID: article.id)
            return false
        }

        try await add(article)
        return true
    }
}
