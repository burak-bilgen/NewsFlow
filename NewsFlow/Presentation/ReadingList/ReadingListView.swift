import Combine
import SwiftUI

// MARK: - Reading List Screen

/// Displays all articles saved to the user's reading list.
@MainActor
struct ReadingListView: View {
    @StateObject private var viewModel: ReadingListViewModel

    init(viewModel: ReadingListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppPalette.screenBackground.ignoresSafeArea()
            content
        }
        .navigationTitle(L10n.text("readingList.title"))
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.load()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ArticlesSkeletonView()
                .transition(.opacity)
        case .loaded(let articles):
            if articles.isEmpty {
                emptyState
            } else {
                articleList(articles: articles)
            }
        case .error(let message):
            StateMessageView(
                systemImage: "exclamationmark.triangle",
                title: L10n.text("error.title"),
                message: message,
                retryTitle: L10n.text("retry.button")
            ) {
                Task { await viewModel.load() }
            }
        }
    }

    private var emptyState: some View {
        StateMessageView(
            systemImage: "bookmark.slash",
            title: L10n.text("readingList.empty.title"),
            message: L10n.text("readingList.empty.message")
        )
    }

    private func articleList(articles: [Article]) -> some View {
        List {
            ForEach(articles) { article in
                ReadingListRow(
                    article: article,
                    onRemove: {
                        Task { await viewModel.remove(article) }
                    }
                )
            }
            .onDelete { indexSet in
                Task { await viewModel.remove(at: indexSet) }
            }
        }
        .listStyle(.plain)
        .background(AppPalette.screenBackground)
    }
}

// MARK: - Reading List Row

private struct ReadingListRow: View {
    let article: Article
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ArticleImageView(url: article.imageURL)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(article.title)
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .lineLimit(2)
                    .foregroundColor(AppPalette.textPrimary)

                Text(article.displayDate)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(AppPalette.textSecondary)
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    onRemove()
                }
                Haptic.light()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppPalette.textSecondary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, AppSpacing.xs)
        .background(AppPalette.screenBackground)
    }
}

// MARK: - View Model

@MainActor
final class ReadingListViewModel: ObservableObject {
    enum State {
        case loading
        case loaded([Article])
        case error(String)
    }

    @Published private(set) var state: State = .loading

    private let useCase: ManageReadingListUseCaseProtocol

    init(useCase: ManageReadingListUseCaseProtocol) {
        self.useCase = useCase
    }

    func load() async {
        do {
            _ = await useCase.savedArticleIDs()
            // In a full implementation, we'd map saved IDs to full Article objects.
            // For now, ReadingListView is toggled inline within ArticlesView.
            state = .loaded([])
        }
    }

    func remove(_ article: Article) async {
        do {
            _ = try await useCase.toggle(article)
            await load()
        } catch {
            state = .error(L10n.text("error.generic"))
        }
    }

    func remove(at offsets: IndexSet) async {
        guard case .loaded(let articles) = state else { return }
        for index in offsets {
            let article = articles[index]
            do {
                _ = try await useCase.toggle(article)
            } catch {
                state = .error(L10n.text("error.generic"))
                return
            }
        }
        await load()
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    NavigationView {
        ReadingListView(
            viewModel: ReadingListViewModel(
                useCase: ManageReadingListUseCase(
                    repository: InMemoryReadingListRepository()
                )
            )
        )
    }
}
#endif
