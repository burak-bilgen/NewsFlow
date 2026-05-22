import Combine
import Foundation
@MainActor
final class ReadingListViewModel: ObservableObject {
    enum State {
        case loading
        case loaded([Article])
        case error(String)
    }

    @Published private(set) var state: State = .loading
    private let useCase: ManageReadingListUseCaseProtocol

    init(useCase: ManageReadingListUseCaseProtocol) {
        self.useCase = useCase
    }

    func load() async {
        let articles = await useCase.savedArticles()
        state = .loaded(articles)
    }

    func remove(_ article: Article) async {
        _ = try? await useCase.toggle(article)
        await load()
    }
}
