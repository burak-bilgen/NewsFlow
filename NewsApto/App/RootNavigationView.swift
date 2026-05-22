import SwiftUI

struct RootNavigationView: View {
    @ObservedObject private var container: AppContainer
    @State private var selectedTab = 0

    init(container: AppContainer) {
        self.container = container
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                FeedView(
                    viewModel: container.makeFeedViewModel(),
                    makeReadingListViewModel: { container.makeReadingListViewModel() },
                    selectedTab: $selectedTab
                )
            }
            .tabItem {
                Label(L10n.text("tab.feed"), systemImage: selectedTab == 0 ? "newspaper.fill" : "newspaper")
            }
            .tag(0)

            NavigationStack {
                ReadingListView(viewModel: container.makeReadingListViewModel())
            }
            .tabItem {
                Label(L10n.text("readinglist.title"), systemImage: selectedTab == 1 ? "bookmark.fill" : "bookmark")
            }
            .tag(1)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label(L10n.text("tab.settings"), systemImage: selectedTab == 2 ? "gearshape.fill" : "gearshape")
            }
            .tag(2)
        }
        .tint(AppPalette.accent)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(AppPalette.background)
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(AppPalette.textTertiary)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(AppPalette.textTertiary)]
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppPalette.accent)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(AppPalette.accent)]
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        .offlineAware()
    }
}
