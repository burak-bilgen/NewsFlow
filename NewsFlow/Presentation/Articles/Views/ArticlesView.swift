import Combine
import SwiftUI

// MARK: - ArticlesView

/// The main article list screen for a selected news source.
/// Features a hero carousel for top stories, thumbnail cards for the rest,
/// and automatic background refresh every 60 seconds.
struct ArticlesView: View {
    @StateObject private var viewModel: ArticlesViewModel
    @State private var carouselTimer = Timer.publish(every: 5, on: .main, in: .common)
    @State private var timerConnection: Cancellable?
    @State private var isCarouselAutoScrollEnabled = true
    @State private var isProgrammaticCarouselAdvance = false
    @State private var searchQuery: String = ""
    @Namespace private var heroAnimation
    var heroNamespace: Namespace.ID?

    init(viewModel: ArticlesViewModel, heroNamespace: Namespace.ID? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.heroNamespace = heroNamespace
    }

    var body: some View {
        ZStack {
            AppPalette.screenBackground.ignoresSafeArea()
            content
        }
        .navigationTitle(viewModel.source.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadIfNeeded()
            viewModel.startAutomaticRefresh()
        }
        .onAppear {
            startCarouselAutoScroll()
        }
        .onDisappear {
            viewModel.stopAutomaticRefresh()
            stopCarouselAutoScroll()
        }
        .onReceive(carouselTimer) { _ in
            guard isCarouselAutoScrollEnabled else { return }
            advanceCarousel()
        }
        .onChange(of: viewModel.carouselSelection) { _ in
            stopCarouselAutoScrollAfterManualSelection()
        }
        .searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: L10n.text("search.placeholder"))
        .onChange(of: searchQuery) { newValue in
            viewModel.updateSearchQuery(newValue)
        }
        .toastOverlay()
        .offlineAware()
        .accessibilityIdentifier("articles.screen")
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ArticlesSkeletonView()
                .transition(.opacity)

        case .loaded:
            articleList
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.97)),
                    removal: .opacity
                ))

        case .empty:
            StateMessageView(
                systemImage: "doc.text.magnifyingglass",
                title: L10n.text("articles.empty.title"),
                message: L10n.text("articles.empty.message"),
                retryTitle: L10n.text("retry.button")
            ) {
                Task { await viewModel.retry() }
            }
            .transition(.opacity)

        case let .error(message):
            StateMessageView(
                systemImage: "exclamationmark.triangle",
                title: L10n.text("error.title"),
                message: message,
                retryTitle: L10n.text("retry.button")
            ) {
                Task { await viewModel.retry() }
            }
            .transition(.opacity)
        }
    }

    private var articleList: some View {
        ScrollView {
            PullToRefreshIndicator(isRefreshing: viewModel.isRefreshing)

            LazyVStack(spacing: AppSpacing.lg) {
                if !viewModel.featuredArticles.isEmpty {
                    FeaturedCarouselView(
                        viewModel: viewModel,
                        heroNamespace: heroNamespace,
                        onManualInteraction: stopCarouselAutoScroll
                    )
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if !viewModel.listArticles.isEmpty {
                    SectionHeaderView(title: L10n.text("articles.latest"))
                        .padding(.horizontal, AppSpacing.md)
                }

                ForEach(Array(viewModel.listArticles.enumerated()), id: \.element.id) { index, article in
                    ArticleCardView(
                        article: article,
                        sourceName: viewModel.source.name,
                        isSaved: viewModel.isSaved(article),
                        onToggle: { Task { await viewModel.toggleReadingList(for: article) } },
                        heroNamespace: heroAnimation
                    )
                    .padding(.horizontal, AppSpacing.md)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                        removal: .opacity
                    ))
                    .animation(
                        .spring(response: 0.55, dampingFraction: 0.75)
                        .delay(Double(index) * 0.05),
                        value: viewModel.state
                    )
                    .onAppear {
                        let threshold = max(viewModel.listArticles.count - 3, 0)
                        if index >= threshold {
                            Task { await viewModel.prefetchNextPageIfNeeded() }
                        }
                        viewModel.prefetchImages(for: viewModel.listArticles)
                    }
                }

                // Load More button for pagination
                if viewModel.hasMorePages {
                    LoadMoreButton(isLoading: viewModel.isLoadingMore) {
                        Task { await viewModel.loadMore() }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.sm)
                }
            }
            .padding(.vertical, AppSpacing.lg)
        }
        .refreshable {
            await viewModel.pullToRefresh()
        }
        .accessibilityIdentifier("articles.list")
    }

    private func advanceCarousel() {
        let count = viewModel.featuredArticles.count
        guard count > 1 else { return }
        isProgrammaticCarouselAdvance = true
        withAnimation(Accessibility.isReduceMotionEnabled ? nil : .easeInOut(duration: 0.4)) {
            viewModel.carouselSelection = (viewModel.carouselSelection + 1) % count
        }
        Task { @MainActor in
            await Task.yield()
            isProgrammaticCarouselAdvance = false
        }
    }

    private func startCarouselAutoScroll() {
        guard timerConnection == nil else { return }
        isCarouselAutoScrollEnabled = true
        timerConnection = carouselTimer.connect()
    }

    private func stopCarouselAutoScroll() {
        isCarouselAutoScrollEnabled = false
        timerConnection?.cancel()
        timerConnection = nil
    }

    private func stopCarouselAutoScrollAfterManualSelection() {
        guard !isProgrammaticCarouselAdvance else { return }
        stopCarouselAutoScroll()
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Articles - Loaded") {
    NavigationView {
        ArticlesView(viewModel: NewsFixture.previewViewModel())
    }
}

#Preview("Articles - Loading") {
    NavigationView {
        ArticlesView(viewModel: NewsFixture.previewViewModel().withState(.loading))
    }
}

#Preview("Articles - Empty") {
    NavigationView {
        ArticlesView(viewModel: NewsFixture.previewViewModel().withState(.empty))
    }
}

#Preview("Articles - Error") {
    NavigationView {
        ArticlesView(viewModel: NewsFixture.previewViewModel().withState(.error("Network connection failed")))
    }
}
#endif
