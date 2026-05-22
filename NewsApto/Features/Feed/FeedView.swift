import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel: FeedViewModel
    let makeReadingListViewModel: () -> ReadingListViewModel
    @Binding var selectedTab: Int
    @State private var showAttribution = false
    @State private var selectedArticle: Article?
    @State private var terminalSearchText = ""

    init(viewModel: FeedViewModel, makeReadingListViewModel: @escaping () -> ReadingListViewModel, selectedTab: Binding<Int>) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.makeReadingListViewModel = makeReadingListViewModel
        _selectedTab = selectedTab
    }

    var body: some View {
        ZStack {
            AppPalette.background.ignoresSafeArea()
            content
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .fullScreenCover(item: $selectedArticle) { article in
            HeroDetailView(
                article: article,
                isSaved: viewModel.isSaved(article),
                onToggle: { Task { await viewModel.toggleReadingList(for: article) } },
                onDismiss: { selectedArticle = nil }
            )
        }
        .sheet(isPresented: $showAttribution) {
            NavigationStack {
                AttributionView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                showAttribution = false
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(AppPalette.accent)
                                    .frame(width: 44, height: 44)
                                    .background(AppPalette.background)
                                    .overlay(Rectangle().stroke(AppPalette.accent, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
            }
        }
        .task { await viewModel.loadIfNeeded() }
        .statusBarHidden(true)
        .accessibilityIdentifier("home.screen")
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle: Color.clear
        case .loading: MatrixCodeRainView().transition(.opacity)
        case .ready: magazineContent.transition(.opacity).glitchReveal()
        case .empty: emptyState.transition(.opacity)
        case .error(let message): errorState(message).transition(.opacity)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Text(L10n.text("feed.empty.title"))
                .font(AppTypography.monoSmall)
                .foregroundColor(AppPalette.textTertiary)
            Text(L10n.text("feed.empty.message"))
                .font(AppTypography.body)
                .foregroundColor(AppPalette.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "wifi.slash")
                .font(.system(size: 36))
                .foregroundColor(AppPalette.error)
            Text(L10n.text("feed.error.title"))
                .font(AppTypography.monoSmall)
                .foregroundColor(AppPalette.error)
            Text(message)
                .font(AppTypography.body)
                .foregroundColor(AppPalette.textSecondary)
                .multilineTextAlignment(.center)
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                Task { await viewModel.pullToRefresh() }
            } label: {
                Text(L10n.text("state.retry"))
                    .font(AppTypography.monoSmall)
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(AppPalette.accent)
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private var magazineContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                // Pull-to-refresh custom indicator at top
                if viewModel.isRefreshing {
                    PullToRefreshLoadingView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity
                        ))
                }

                FeedHeaderView(
                    onAttributionTap: { showAttribution = true },
                    selectedTab: $selectedTab
                )

                TerminalSearchBar(text: $terminalSearchText) { query in
                    viewModel.searchQuery = query
                }
                .onChange(of: terminalSearchText) { _, newValue in
                    viewModel.searchQuery = newValue
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)

                Rectangle()
                    .fill(AppPalette.accent.opacity(0.3))
                    .frame(height: 0.5)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                categoryRibbon
                    .padding(.bottom, 12)

                let feedArticles = viewModel.filteredByCategory
                let filterHash = viewModel.searchQuery

                Group {
                    let hero = feedArticles.first { $0.imageURL != nil } ?? feedArticles.first
                    let rest = feedArticles.filter { article in hero.map { $0.id != article.id } ?? true }

                    VStack(alignment: .leading, spacing: 0) {
                        if let heroArticle = hero {
                            HeroCardView(
                                article: heroArticle,
                                onSelect: { selectedArticle = heroArticle },
                                onToggle: { Task { await viewModel.toggleReadingList(for: heroArticle) } },
                                isSaved: viewModel.isSaved(heroArticle)
                            )
                        }

                        if !rest.isEmpty {
                            featuredGrid(Array(rest.prefix(4)))
                            let latest = Array(rest.dropFirst(4))
                            if !latest.isEmpty {
                                latestSection(latest)
                            }
                        }

                        if viewModel.hasMorePages {
                            loadMoreFooter
                        }
                    }
                }
                .matrixEmission(trigger: filterHash)
            }
        }
        .refreshable { await viewModel.pullToRefresh() }
    }

    private func featuredGrid(_ articles: [Article]) -> some View {
        Group {
            if !articles.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    sectionHeader(L10n.text("feed.editors_picks"))

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10)
                        ],
                        spacing: 10
                    ) {
                        ForEach(articles) { article in
                            MagazineGridCard(
                                article: article,
                                isSaved: viewModel.isSaved(article),
                                onToggle: { Task { await viewModel.toggleReadingList(for: article) } },
                                onSelect: { selectedArticle = article }
                            )
                            .id(article.id + "-grid")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
        }
    }

    private func latestSection(_ articles: [Article]) -> some View {
        Group {
            if !articles.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    sectionHeader(L10n.text("feed.latest"))

                    LazyVStack(spacing: 0) {
                        ForEach(Array(articles.enumerated()), id: \.offset) { i, article in
                            MagazineListCard(
                                article: article,
                                isSaved: viewModel.isSaved(article),
                                onToggle: { Task { await viewModel.toggleReadingList(for: article) } },
                                onSelect: { selectedArticle = article }
                            )
                            .id(article.id + "-list-\(i)")
                            .onAppear { viewModel.prefetchIfNeeded(currentItem: article) }

                            if i < articles.count - 1 {
                                Rectangle()
                                    .fill(AppPalette.dividerBorder)
                                    .frame(height: 0.5)
                                    .padding(.leading, 100)
                            }
                        }
                    }
                }
            }
        }
    }

    private var loadMoreFooter: some View {
        Group {
            if viewModel.isLoadingMore {
                FeedPaginationLoadingView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    Task { await viewModel.loadMore() }
                } label: {
                    Text(L10n.text("feed.load_more"))
                        .font(AppTypography.monoSmall)
                        .foregroundColor(AppPalette.accent)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var categoryRibbon: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(title: L10n.text("category.all"), isSelected: viewModel.selectedCategory == nil) {
                    viewModel.selectedCategory = nil
                }
                ForEach(viewModel.availableCategories, id: \.self) { category in
                    categoryChip(title: category, isSelected: viewModel.selectedCategory == category) {
                        viewModel.selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func categoryChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Text(title.uppercased())
                .font(AppTypography.monoTiny.weight(.bold))
                .foregroundColor(isSelected ? .black : AppPalette.accent)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? AppPalette.accent : AppPalette.surface)
                .overlay(Rectangle().stroke(isSelected ? AppPalette.accent : AppPalette.accent.opacity(0.3), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(AppTypography.small.weight(.bold))
            .foregroundColor(AppPalette.accent)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 10)
    }
}

