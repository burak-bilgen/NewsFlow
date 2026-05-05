import Foundation

// MARK: - Fetch Sources Use Case

protocol FetchSourcesUseCaseProtocol {
    func execute() async throws -> [NewsSource]
}

final class FetchSourcesUseCase: FetchSourcesUseCaseProtocol {
    private let repository: SourcesRepositoryProtocol

    init(repository: SourcesRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> [NewsSource] {
        try await repository.fetchSources()
    }
}
