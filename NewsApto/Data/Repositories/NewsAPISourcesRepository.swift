import Foundation

final class NewsAPISourcesRepository: SourcesRepositoryProtocol {
    private let client: NewsAPIClientProtocol

    init(client: NewsAPIClientProtocol) {
        self.client = client
    }

    func fetchSources() async throws -> [NewsSource] {
        let response = try await client.request(SourcesResponseDTO.self, endpoint: .sources)
        return response.sources.compactMap { $0.domainModel() }
    }
}
