import SwiftUI

@MainActor
struct ReadingListView: View {
    @StateObject private var viewModel: ReadingListViewModel
    @State private var selectedArticle: Article?
    @State private var cursorVisible = true

    init(viewModel: ReadingListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppPalette.background.ignoresSafeArea()
            content
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(L10n.text("readinglist.title"))
                    .font(AppTypography.monoSmall)
                    .foregroundColor(AppPalette.accent)
            }
        }
        .fullScreenCover(item: $selectedArticle) { article in
            HeroDetailView(
                article: article,
                isSaved: true,
                onToggle: {
                    Task {
                        await viewModel.remove(article)
                        selectedArticle = nil
                    }
                },
                onDismiss: { selectedArticle = nil }
            )
        }
        .task { await viewModel.load() }
        .statusBarHidden(true)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            loadingState
        case .loaded(let articles):
            if articles.isEmpty {
                emptyState
            } else {
                articleList(articles: articles)
            }
        case .error:
            emptyState
        }
    }

    private var loadingState: some View {
        VStack {
            Spacer()
            HStack(spacing: 6) {
                Text(L10n.text("readinglist.loading"))
                    .font(AppTypography.monoSmall)
                    .foregroundColor(AppPalette.accent)
                Text("_")
                    .font(AppTypography.monoSmall.weight(.bold))
                    .foregroundColor(AppPalette.accent)
                    .opacity(cursorVisible ? 1 : 0.3)
            }
            Spacer()
        }
        .onAppear {
            withAnimation(AppAnimation.blink) { cursorVisible = false }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Text(L10n.text("readinglist.empty.title"))
                .font(AppTypography.monoSmall)
                .foregroundColor(AppPalette.textTertiary)
            Text(L10n.text("readinglist.empty.message"))
                .font(AppTypography.body)
                .foregroundColor(AppPalette.textSecondary)
            Spacer()
        }
    }

    private func articleList(articles: [Article]) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(articles.enumerated()), id: \.element.id) { i, article in
                    ReadingListRow(
                        article: article,
                        onSelect: { selectedArticle = article },
                        onRemove: { Task { await viewModel.remove(article) } }
                    )

                    if i < articles.count - 1 {
                        Rectangle()
                            .fill(AppPalette.dividerBorder)
                            .frame(height: 0.5)
                            .padding(.leading, 100)
                    }
                }
            }
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
    }
}

