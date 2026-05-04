import SwiftUI

struct RootNavigationView: View {
    @ObservedObject private var container: AppContainer

    init(container: AppContainer) {
        self.container = container
    }

    var body: some View {
        NavigationView {
            SourcesView(
                viewModel: container.makeSourcesViewModel(),
                articlesViewModel: { source in
                    container.makeArticlesViewModel(source: source)
                }
            )
        }
        .navigationViewStyle(.stack)
    }
}
