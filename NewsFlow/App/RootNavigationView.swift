import Combine
import SwiftUI

protocol AppRouterProtocol: AnyObject {
    func navigateToArticles(for source: NewsSource)
}

@MainActor
final class AppRouter: ObservableObject, AppRouterProtocol {
    @Published var selectedSource: NewsSource?

    func navigateToArticles(for source: NewsSource) {
        selectedSource = source
    }
}

struct RootNavigationView: View {
    @ObservedObject private var container: AppContainer
    @StateObject private var router = AppRouter()
    @Namespace private var heroAnimation

    init(container: AppContainer) {
        self.container = container
    }

    var body: some View {
        NavigationView {
            SourcesView(
                viewModel: container.makeSourcesViewModel(),
                articlesViewModel: { source in
                    container.makeArticlesViewModel(source: source)
                },
                heroNamespace: heroAnimation
            )
        }
        .navigationViewStyle(.stack)
        .environmentObject(router)
    }
}
