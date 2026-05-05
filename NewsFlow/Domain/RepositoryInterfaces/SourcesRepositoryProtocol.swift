import Foundation

protocol SourcesRepositoryProtocol {
    func fetchSources() async throws -> [NewsSource]
}
