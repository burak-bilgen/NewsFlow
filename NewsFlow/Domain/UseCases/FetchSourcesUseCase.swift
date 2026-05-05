import Foundation

// MARK: - Fetch Sources Use Case

protocol FetchSourcesUseCaseProtocol {
    func execute(bypassCache: Bool) async throws -> [NewsSource]
}

final class FetchSourcesUseCase: FetchSourcesUseCaseProtocol {
    private let repository: SourcesRepositoryProtocol
    
    init(repository: SourcesRepositoryProtocol) {
        self.repository = repository
    }

    func execute(bypassCache: Bool = false) async throws -> [NewsSource] {
        if bypassCache, let cacheBypassingRepo = repository as? SourcesCacheBypassing {
            return try await cacheBypassingRepo.fetchSourcesBypassingCache()
        }
        return try await repository.fetchSources()
    }
}
