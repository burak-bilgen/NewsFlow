import SwiftUI

@MainActor
struct ReadingListView: View {
    @StateObject private var viewModel: ReadingListViewModel
    @State private var selectedArticle: Article?

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
                Text("> READING.LIST")
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
                Text("> LOADING")
                    .font(AppTypography.monoSmall)
                    .foregroundColor(AppPalette.accent)
                Text("_")
                    .font(AppTypography.monoSmall.weight(.bold))
                    .foregroundColor(AppPalette.accent)
                    .opacity(0.6)
                    .animation(AppAnimation.blink, value: true)
            }
            Spacer()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("> EMPTY")
                .font(AppTypography.monoSmall)
                .foregroundColor(AppPalette.textTertiary)
            Text("No saved articles")
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

