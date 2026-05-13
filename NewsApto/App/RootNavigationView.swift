import SwiftUI

struct RootNavigationView: View {
    @ObservedObject private var container: AppContainer

    init(container: AppContainer) {
        self.container = container
    }

    var body: some View {
        NavigationView {
            FeedView(
                viewModel: container.makeFeedViewModel(),
                makeReadingListViewModel: { container.makeReadingListViewModel() }
            )
        }
        .navigationViewStyle(.stack)
    }
}
