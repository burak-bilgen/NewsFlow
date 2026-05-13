import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel: FeedViewModel
    let makeSourcesViewModel: () -> SourcesViewModel
    let makeArticlesViewModel: (NewsSource) -> ArticlesViewModel
    let makeReadingListViewModel: () -> ReadingListViewModel
    @State private var showAttribution = false
    @State private var selectedArticle: Article?
    @State private var terminalSearchText = ""

    init(viewModel: FeedViewModel, makeSourcesViewModel: @escaping () -> SourcesViewModel, makeArticlesViewModel: @escaping (NewsSource) -> ArticlesViewModel, makeReadingListViewModel: @escaping () -> ReadingListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.makeSourcesViewModel = makeSourcesViewModel
        self.makeArticlesViewModel = makeArticlesViewModel
        self.makeReadingListViewModel = makeReadingListViewModel
    }

    var body: some View {
        ZStack {
            AppPalette.background.ignoresSafeArea()
            content
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 2) {
                    NavigationLink { ReadingListView(viewModel: makeReadingListViewModel()) } label: {
                        Image(systemName: "text.book.closed").font(.system(size: 13, weight: .medium)).foregroundColor(AppPalette.textSecondary).frame(width: 34, height: 34).contentShape(Rectangle())
                    }
                    Button { showAttribution = true } label: {
                        Image(systemName: "line.3.horizontal").font(.system(size: 13, weight: .medium)).foregroundColor(AppPalette.textSecondary).frame(width: 34, height: 34).contentShape(Rectangle())
                    }
                }
            }
        }
        .fullScreenCover(item: $selectedArticle) { article in
            HeroDetailView(article: article, isSaved: viewModel.isSaved(article), onToggle: { Task { await viewModel.toggleReadingList(for: article) } }, onDismiss: { selectedArticle = nil })
        }
        .sheet(isPresented: $showAttribution) {
            NavigationView { AttributionView().toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button { showAttribution = false } label: { Image(systemName: "xmark.circle.fill").font(.system(size: 20)).foregroundColor(AppPalette.textTertiary) } } } }
        }
        .task { await viewModel.loadIfNeeded() }
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
        VStack(spacing: 12) { Spacer()
            Text("> NO.DATA").font(AppTypography.monoSmall).foregroundColor(AppPalette.textTertiary)
            Text("No articles match your filter.").font(AppTypography.body).foregroundColor(AppPalette.textSecondary).multilineTextAlignment(.center)
            Spacer()
        }.padding(.horizontal, 32)
    }

    private var magazineContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                logoHeader
                
                TerminalSearchBar(text: $terminalSearchText) { query in
                    viewModel.searchQuery = query
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)

                TerminalCategoryRibbon(selected: $viewModel.selectedCategory)
                    .padding(.bottom, 24)

                Rectangle()
                    .fill(AppPalette.accent.opacity(0.3))
                    .frame(height: 0.5)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                let feedArticles = viewModel.filteredArticles
                let filterHash = "\(viewModel.selectedCategory ?? "all")-\(viewModel.searchQuery)"

                Group {
                    if let article = feedArticles.first {
                        VStack(alignment: .leading, spacing: 0) {
                            heroSection(for: article)
                            if feedArticles.count > 1 {
                                featuredGrid(Array(feedArticles.dropFirst().prefix(4)))
                                latestSection(Array(feedArticles.dropFirst(5)))
                            }
                        }
                    } else if viewModel.state == .ready {
                        VStack(spacing: 12) {
                            Spacer().frame(height: 40)
                            Image(systemName: "magnifyingglass").font(.system(size: 32)).foregroundColor(AppPalette.textTertiary)
                            Text("> CATEGORY: EMPTY").font(AppTypography.monoSmall).foregroundColor(AppPalette.textTertiary)
                            Text("No articles match \(viewModel.selectedCategory?.uppercased() ?? "this filter").").font(AppTypography.caption).foregroundColor(AppPalette.textSecondary)
                            Spacer().frame(height: 40)
                        }.frame(maxWidth: .infinity)
                    }
                }
                .matrixEmission(trigger: filterHash)
            }
        }
        .refreshable { await viewModel.pullToRefresh() }
    }

    private var logoHeader: some View {
        Image("logo").resizable().scaledToFit().frame(width: 60, height: 60)
            .padding(.leading, 20).padding(.top, -45).padding(.bottom, 25)
    }

    private func heroSection(for article: Article) -> some View {
        Button { selectedArticle = article } label: {
            ZStack(alignment: .bottomLeading) {
                ArticleImageView(url: article.imageURL).frame(height: 320).clipped()
                LinearGradient(colors: [.clear, .black.opacity(0.75)], startPoint: .top, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 6) {
                    Text(article.sourceName.uppercased()).font(AppTypography.small.weight(.bold)).foregroundColor(AppPalette.accent)
                    Text(article.title).font(AppTypography.largeTitle).foregroundColor(.white).lineLimit(3)
                    if let desc = article.description, !desc.isEmpty {
                        Text(desc).font(AppTypography.body).foregroundColor(.white.opacity(0.8)).lineLimit(2)
                    }
                }.padding(16)
            }
        }.buttonStyle(.plain)
    }

    private func featuredGrid(_ articles: [Article]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Editor's Picks")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(Array(articles.enumerated()), id: \.element.id) { i, article in
                    MagazineGridCard(article: article, isSaved: viewModel.isSaved(article), onToggle: { Task { await viewModel.toggleReadingList(for: article) } }, onSelect: { selectedArticle = article })
                }
            }.padding(.horizontal, 16).padding(.bottom, 20)
        }
    }

    private func latestSection(_ articles: [Article]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Latest")
            LazyVStack(spacing: 0) {
                ForEach(Array(articles.enumerated()), id: \.element.id) { i, article in
                    MagazineListCard(article: article, isSaved: viewModel.isSaved(article), onToggle: { Task { await viewModel.toggleReadingList(for: article) } }, onSelect: { selectedArticle = article })
                    if i < articles.count - 1 { Rectangle().fill(AppPalette.dividerBorder).frame(height: 0.5).padding(.leading, 100) }
                }
                if viewModel.hasMorePages && viewModel.selectedCategory == nil {
                    Button { Task { await viewModel.loadMore() } } label: {
                        Text("> LOAD.MORE").font(AppTypography.monoSmall).foregroundColor(AppPalette.accent).frame(maxWidth: .infinity).padding(.vertical, 14)
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased()).font(AppTypography.small.weight(.bold)).foregroundColor(AppPalette.accent).padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 10)
    }
}

struct MagazineGridCard: View {
    let article: Article; let isSaved: Bool; let onToggle: () -> Void; let onSelect: () -> Void
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 0) {
                ArticleImageView(url: article.imageURL).frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120).clipped()
                VStack(alignment: .leading, spacing: 4) {
                    Text(article.sourceName.uppercased()).font(AppTypography.small.weight(.bold)).foregroundColor(AppPalette.accent)
                    Text(article.title).font(AppTypography.caption.weight(.semibold)).foregroundColor(AppPalette.textPrimary).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                    Text(article.displayDate).font(AppTypography.small).foregroundColor(AppPalette.textTertiary)
                }.padding(8)
            }.background(AppPalette.surface).overlay(Rectangle().stroke(AppPalette.cardBorder, lineWidth: 0.5))
        }.buttonStyle(.plain).contentShape(Rectangle())
    }
}

struct MagazineListCard: View {
    let article: Article; let isSaved: Bool; let onToggle: () -> Void; let onSelect: () -> Void
    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 12) {
                ArticleImageView(url: article.imageURL).frame(width: 80, height: 80).clipped()
                VStack(alignment: .leading, spacing: 3) {
                    Text(article.sourceName.uppercased()).font(AppTypography.small.weight(.bold)).foregroundColor(AppPalette.accent)
                    Text(article.title).font(AppTypography.caption.weight(.semibold)).foregroundColor(AppPalette.textPrimary).lineLimit(2)
                    Text(article.displayDate).font(AppTypography.small).foregroundColor(AppPalette.textTertiary)
                }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 2)
            }.padding(.vertical, 12).padding(.horizontal, 20).contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
}
