import Combine
import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel: FeedViewModel
    let makeSourcesViewModel: () -> SourcesViewModel
    let makeArticlesViewModel: (NewsSource) -> ArticlesViewModel
    @State private var carouselTimer = Timer.publish(every: 5, on: .main, in: .common)
    @State private var timerConnection: Cancellable?
    @State private var isCarouselAutoScrollEnabled = true
    @State private var isProgrammaticCarouselAdvance = false
    @State private var showSourceBrowser = false
    @Namespace private var heroAnimation

    init(
        viewModel: FeedViewModel,
        makeSourcesViewModel: @escaping () -> SourcesViewModel,
        makeArticlesViewModel: @escaping (NewsSource) -> ArticlesViewModel
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.makeSourcesViewModel = makeSourcesViewModel
        self.makeArticlesViewModel = makeArticlesViewModel
    }

    var body: some View {
        ZStack {
            AppPalette.screenBackground.ignoresSafeArea()
            content
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 4) {
                    Button {
                        showSourceBrowser = true
                    } label: {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppPalette.primaryRed)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(AppPalette.primaryRedMuted))
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppPalette.primaryRed)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(AppPalette.primaryRedMuted))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .task { await viewModel.loadIfNeeded() }
        .onAppear { startCarouselAutoScroll() }
        .onDisappear { stopCarouselAutoScroll() }
        .onReceive(carouselTimer) { _ in
            guard isCarouselAutoScrollEnabled else { return }
            advanceCarousel()
        }
        .onChange(of: viewModel.carouselSelection) { _ in
            stopCarouselAutoScrollAfterManualSelection()
        }
        .sheet(isPresented: $showSourceBrowser) {
            NavigationView {
                SourcesView(
                    viewModel: makeSourcesViewModel(),
                    articlesViewModel: makeArticlesViewModel
                )
            }
        }
        .toastOverlay()
        .offlineAware()
        .accessibilityIdentifier("feed.screen")
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
                systemImage: "sparkles.rectangle.stack",
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
                mastheadHeader
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.sm)
                    .padding(.bottom, AppSpacing.lg)

                if !viewModel.featuredArticles.isEmpty {
                    FeedCarouselView(
                        articles: viewModel.featuredArticles,
                        isSaved: { viewModel.isSaved($0) },
                        onToggleSave: { article in Task { await viewModel.toggleReadingList(for: article) } },
                        carouselSelection: $viewModel.carouselSelection,
                        onManualInteraction: stopCarouselAutoScroll,
                        heroNamespace: heroAnimation
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
                        sourceName: article.sourceName,
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
                        .delay(Double(index) * 0.03),
                        value: viewModel.articles.count
                    )
                    .onAppear {
                        let threshold = max(viewModel.listArticles.count - 3, 0)
                        if index >= threshold {
                            Task { await viewModel.prefetchNextPageIfNeeded() }
                        }
                    }
                }

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
        .refreshable { await viewModel.pullToRefresh() }
        .accessibilityIdentifier("feed.list")
    }

    private var mastheadHeader: some View {
        VStack(spacing: 0) {
            newspaperDivider.padding(.bottom, AppSpacing.sm)

                HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
                Text("NEWS")
                    .font(.system(size: 44, weight: .black, design: .serif))
                    .foregroundColor(AppPalette.textPrimary)
                Text("FLOW")
                    .font(.system(size: 44, weight: .black, design: .serif))
                    .foregroundColor(AppPalette.primaryRed)
            }
            .shadow(color: Color.black.opacity(0.12), radius: 2, x: 1, y: 1)

            Text(L10n.text("sources.mastheadSubtitle"))
                .font(.system(size: 10, weight: .semibold, design: .serif))
                .foregroundColor(AppPalette.textSecondary)
                .textCase(.uppercase)
                .padding(.top, 2)

            VStack(spacing: 2) {
                newspaperDivider
                newspaperDivider
            }
            .padding(.vertical, AppSpacing.sm)

            HStack {
                Text(Date(), style: .date)
                    .font(.system(size: 11, weight: .semibold, design: .serif))
                    .foregroundColor(AppPalette.textSecondary)
                    .textCase(.uppercase)
                Spacer()
                Text("AI-Powered")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(AppPalette.primaryRed)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppPalette.primaryRedMuted, in: Capsule())
            }

            newspaperDivider.padding(.top, AppSpacing.sm)
        }
    }

    private var newspaperDivider: some View {
        Rectangle()
            .fill(AppPalette.textPrimary.opacity(0.85))
            .frame(height: 1)
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

#if DEBUG
#Preview("Feed - Loaded") {
    let repo = MockArticlesRepository(articlesBySource: NewsFixture.articlesBySource)
    let readingList = InMemoryReadingListRepository()
    NavigationView {
        FeedView(
            viewModel: FeedViewModel(
                feedUseCase: FetchFeedUseCase(repository: repo),
                readingListUseCase: ManageReadingListUseCase(repository: readingList)
            ),
            makeSourcesViewModel: {
                SourcesViewModel(fetchUseCase: FetchSourcesUseCase(repository: MockSourcesRepository(sources: NewsFixture.sources)))
            },
            makeArticlesViewModel: { source in
                ArticlesViewModel(
                    source: source,
                    fetchUseCase: FetchArticlesUseCase(repository: repo),
                    readingListUseCase: ManageReadingListUseCase(repository: readingList)
                )
            }
        )
    }
}
#endif
