import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel: FeedViewModel
    let makeReadingListViewModel: () -> ReadingListViewModel
    @State private var showAttribution = false
    @State private var selectedArticle: Article?
    @State private var terminalSearchText = ""

    init(viewModel: FeedViewModel, makeReadingListViewModel: @escaping () -> ReadingListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.makeReadingListViewModel = makeReadingListViewModel
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
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("> NO.DATA")
                .font(AppTypography.monoSmall)
                .foregroundColor(AppPalette.textTertiary)
            Text("No articles match your filter.")
                .font(AppTypography.body)
                .foregroundColor(AppPalette.textSecondary)
                .multilineTextAlignment(.center)
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
                    onReadingListTap: { /* Navigation handled by NavigationLink in FeedHeaderView */ },
                    onAttributionTap: { showAttribution = true }
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

                let feedArticles = viewModel.filteredArticles
                let filterHash = viewModel.searchQuery

                Group {
                    // Find first article with image for hero banner (skip HackerNews and image-less articles)
                    let heroArticle = feedArticles.first { $0.imageURL != nil && $0.apiSource != .hackernews }
                    let remainingArticles = heroArticle != nil ? feedArticles.filter { $0.id != heroArticle!.id } : feedArticles
                    
                    if let article = heroArticle {
                        VStack(alignment: .leading, spacing: 0) {
                            HeroCardView(
                                article: article,
                                onSelect: { selectedArticle = article },
                                onToggle: { Task { await viewModel.toggleReadingList(for: article) } },
                                isSaved: viewModel.isSaved(article)
                            )

                            let featuredArticles = Array(remainingArticles.prefix(4))
                            let latestArticles = Array(remainingArticles.dropFirst(5))

                            if !featuredArticles.isEmpty {
                                featuredGrid(featuredArticles)
                            }

                            if !latestArticles.isEmpty {
                                latestSection(latestArticles)
                            }

                            if viewModel.hasMorePages {
                                loadMoreFooter
                            }
                        }
                    } else if viewModel.state == .ready {
                        categoryEmptyState
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
                    sectionHeader("Editor's Picks")

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10)
                        ],
                        spacing: 10
                    ) {
                        ForEach(articles, id: \.id) { article in
                            MagazineGridCard(
                                article: article,
                                isSaved: viewModel.isSaved(article),
                                onToggle: { Task { await viewModel.toggleReadingList(for: article) } },
                                onSelect: { selectedArticle = article }
                            )
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
                    sectionHeader("Latest")

                    LazyVStack(spacing: 0) {
                        ForEach(Array(articles.enumerated()), id: \.element.id) { i, article in
                            MagazineListCard(
                                article: article,
                                isSaved: viewModel.isSaved(article),
                                onToggle: { Task { await viewModel.toggleReadingList(for: article) } },
                                onSelect: { selectedArticle = article }
                            )
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
                    Text("> LOAD.MORE")
                        .font(AppTypography.monoSmall)
                        .foregroundColor(AppPalette.accent)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var categoryEmptyState: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 40)

            Image(systemName: "magnifyingglass")
                .font(.system(size: 32))
                .foregroundColor(AppPalette.textTertiary)

            Text("> CATEGORY: EMPTY")
                .font(AppTypography.monoSmall)
                .foregroundColor(AppPalette.textTertiary)

            Text("No articles match your search.")
                .font(AppTypography.caption)
                .foregroundColor(AppPalette.textSecondary)

            Spacer().frame(height: 40)
        }
        .frame(maxWidth: .infinity)
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

