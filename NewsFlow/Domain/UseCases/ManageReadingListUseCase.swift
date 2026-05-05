import Foundation

// MARK: - Manage Reading List Use Case

protocol ManageReadingListUseCaseProtocol {
    func toggle(_ article: Article) async throws -> Bool
    func isSaved(articleID: String) async -> Bool
    func savedArticleIDs() async -> Set<String>
}

final class ManageReadingListUseCase: ManageReadingListUseCaseProtocol {
    private let repository: ReadingListRepositoryProtocol

    init(repository: ReadingListRepositoryProtocol) {
        self.repository = repository
    }

    func toggle(_ article: Article) async throws -> Bool {
        try await repository.toggle(article)
    }

    func isSaved(articleID: String) async -> Bool {
        await repository.isSaved(articleID: articleID)
    }

    func savedArticleIDs() async -> Set<String> {
        await repository.savedArticleIDs()
    }
}
