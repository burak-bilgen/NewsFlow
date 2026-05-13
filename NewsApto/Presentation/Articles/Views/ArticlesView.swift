import Combine
import SwiftUI

struct ArticlesView: View {
    @StateObject private var viewModel: ArticlesViewModel
    @State private var searchQuery: String = ""
    @Namespace private var heroAnimation
    var heroNamespace: Namespace.ID?

    init(viewModel: ArticlesViewModel, heroNamespace: Namespace.ID? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.heroNamespace = heroNamespace
    }

    var body: some View {
        ZStack {
            AppPalette.background.ignoresSafeArea()
            content
        }
        .navigationTitle(viewModel.source.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadIfNeeded()
        }
        .searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: L10n.text("search.placeholder"))
        .onChange(of: searchQuery) { _, newValue in
            viewModel.updateSearchQuery(newValue)
        }
        .offlineAware()
        .accessibilityIdentifier("articles.screen")
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            Color.clear
        case .loading:
            ArticlesSkeletonView()
        case .loaded:
            loadedContent
        case .empty:
            StateMessageView(
                systemImage: "newspaper",
                title: L10n.text("articles.empty.title"),
                message: L10n.text("articles.empty.message")
            )
        }
    }

    private var loadedContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if !viewModel.featuredArticles.isEmpty {
                    FeaturedCarouselView(
                        viewModel: viewModel,
                        heroNamespace: heroAnimation
                    )
                    .frame(height: 400)
                }

                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(viewModel.listArticles.enumerated()), id: \.element.id) { index, article in
                        ArticleCardView(
                            article: article,
                            sourceName: viewModel.source.name,
                            isSaved: viewModel.isSaved(article),
                            onToggle: { Task { await viewModel.toggleReadingList(for: article) } }
                        )
                        .onAppear {
                            let threshold = max(viewModel.listArticles.count - 4, 0)
                            if index >= threshold {
                                Task { await viewModel.loadMore() }
                            }
                        }
                    }

                    if viewModel.isLoadingMore {
                        HStack {
                            Spacer()
                            ProgressView()
                                .padding()
                            Spacer()
                        }
                    }

                    if viewModel.hasMorePages && !viewModel.isLoadingMore {
                        LoadMoreButton(isLoading: viewModel.isLoadingMore) {
                            Task { await viewModel.loadMore() }
                        }
                    }
                }
            }
        }
        .refreshable {
            await viewModel.pullToRefresh()
        }
    }
}
