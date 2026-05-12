import SwiftUI

struct MainTabView: View {
    let container: AppContainer
    @State private var selectedTab = Tab.feed

    enum Tab: Int, CaseIterable {
        case feed
        case sources
        case readingList
        case settings

        var icon: String {
            switch self {
            case .feed: return "newspaper"
            case .sources: return "square.grid.2x2"
            case .readingList: return "bookmark"
            case .settings: return "gearshape"
            }
        }

        var selectedIcon: String {
            switch self {
            case .feed: return "newspaper.fill"
            case .sources: return "square.grid.2x2.fill"
            case .readingList: return "bookmark.fill"
            case .settings: return "gearshape.fill"
            }
        }

        var title: String {
            switch self {
            case .feed: return L10n.text("tab.feed")
            case .sources: return L10n.text("tab.sources")
            case .readingList: return L10n.text("tab.readingList")
            case .settings: return L10n.text("tab.settings")
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView(
                viewModel: container.makeFeedViewModel(),
                makeSourcesViewModel: { container.makeSourcesViewModel() },
                makeArticlesViewModel: { container.makeArticlesViewModel(source: $0) }
            )
            .tabItem {
                Label(Tab.feed.title, systemImage: selectedTab == .feed ? Tab.feed.selectedIcon : Tab.feed.icon)
            }
            .tag(Tab.feed)

            NavigationView {
                SourcesListView(container: container)
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label(Tab.sources.title, systemImage: selectedTab == .sources ? Tab.sources.selectedIcon : Tab.sources.icon)
            }
            .tag(Tab.sources)

            NavigationView {
                ReadingListView(viewModel: container.makeReadingListViewModel())
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label(Tab.readingList.title, systemImage: selectedTab == .readingList ? Tab.readingList.selectedIcon : Tab.readingList.icon)
            }
            .tag(Tab.readingList)

            NavigationView {
                SettingsView()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label(Tab.settings.title, systemImage: selectedTab == .settings ? Tab.settings.selectedIcon : Tab.settings.icon)
            }
            .tag(Tab.settings)
        }
        .tint(AppPalette.brandPrimary)
    }
}

private struct SourcesListView: View {
    let container: AppContainer
    @Namespace private var heroAnimation

    var body: some View {
        SourcesView(
            viewModel: container.makeSourcesViewModel(),
            articlesViewModel: { container.makeArticlesViewModel(source: $0) },
            heroNamespace: heroAnimation
        )
    }
}
