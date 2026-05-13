import Foundation

protocol SourcesRepositoryProtocol {
    func fetchSources() async throws -> [NewsSource]
}

protocol SourcesCacheBypassing {
    func fetchSourcesBypassingCache() async throws -> [NewsSource]
}
