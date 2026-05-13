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
                Text("> READING.LIST").font(AppTypography.monoSmall).foregroundColor(AppPalette.accent)
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
            VStack { Spacer(); Text("> LOADING...").font(AppTypography.monoSmall).foregroundColor(AppPalette.textTertiary); Spacer() }
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

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("> EMPTY").font(AppTypography.monoSmall).foregroundColor(AppPalette.textTertiary)
            Text("No saved articles").font(AppTypography.body).foregroundColor(AppPalette.textSecondary)
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
                        Rectangle().fill(AppPalette.dividerBorder).frame(height: 0.5).padding(.leading, 100)
                    }
                }
            }
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
    }
}

private struct ReadingListRow: View {
    let article: Article
    let onSelect: () -> Void
    let onRemove: () -> Void
    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onSelect) {
                HStack(spacing: 12) {
                    ArticleImageView(url: article.imageURL)
                        .frame(width: 72, height: 72).clipped()
                        .overlay(Rectangle().stroke(AppPalette.cardBorder, lineWidth: 0.5))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(article.sourceName.uppercased())
                            .font(AppTypography.small.weight(.bold)).foregroundColor(AppPalette.accent)
                        Text(article.title)
                            .font(AppTypography.caption.weight(.semibold)).foregroundColor(AppPalette.textPrimary).lineLimit(2)
                        Text(article.displayDate)
                            .font(AppTypography.small).foregroundColor(AppPalette.textTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: onRemove) {
                Image(systemName: "trash")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppPalette.accent)
                    .frame(width: 32, height: 32)
                    .overlay(Rectangle().stroke(AppPalette.accent.opacity(0.3), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        }
        .padding(.vertical, 12).padding(.horizontal, 16)
        .opacity(isVisible ? 1 : 0).offset(y: isVisible ? 0 : 8)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25).delay(Double(0))) { isVisible = true }
        }
    }
}
