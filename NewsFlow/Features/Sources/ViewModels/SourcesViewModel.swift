import Foundation
import Combine

@MainActor
final class SourcesViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case empty
        case error(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var sources: [NewsSource] = []

    private let repository: SourcesRepositoryProtocol
    private var latestRequestID = UUID()

    init(repository: SourcesRepositoryProtocol) {
        self.repository = repository
    }

    func load() async {
        guard state != .loading else { return }
        let requestID = UUID()
        latestRequestID = requestID
        state = .loading

        do {
            let fetchedSources = try await repository.fetchSources()
            guard latestRequestID == requestID else { return }

            sources = SourceFilterService.englishSources(from: fetchedSources)
            state = sources.isEmpty ? .empty : .loaded
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
