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

    init(container: AppContainer) {
        self.container = container
    }

    var body: some View {
        MainTabView(container: container)
            .environmentObject(router)
            .onAppear {
                AppLaunchMetrics.recordLaunchCompleted()
            }
    }
}
