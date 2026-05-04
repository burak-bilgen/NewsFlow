import SwiftUI

struct SourcesView: View {
    @StateObject private var viewModel: SourcesViewModel
    private let articlesViewModel: (NewsSource) -> ArticlesViewModel

    init(
        viewModel: SourcesViewModel,
        articlesViewModel: @escaping (NewsSource) -> ArticlesViewModel
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.articlesViewModel = articlesViewModel
    }

    var body: some View {
        ZStack {
            AppPalette.screenBackground.ignoresSafeArea()
            content
        }
        .navigationTitle(L10n.text("sources.title"))
        .task {
            await viewModel.load()
        }
        .accessibilityIdentifier("sources.screen")
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            LoadingStateView(text: L10n.text("sources.loading"))
        case .loaded:
            sourceList
        case .empty:
            StateMessageView(
                systemImage: "newspaper",
                title: L10n.text("sources.empty.title"),
                message: L10n.text("sources.empty.message")
            )
        case let .error(message):
            StateMessageView(
                systemImage: "exclamationmark.triangle",
                title: L10n.text("error.title"),
                message: message,
                retryTitle: L10n.text("retry.button")
            ) {
                Task { await viewModel.retry() }
            }
        }
    }

    private var sourceList: some View {
        List {
            ForEach(viewModel.sources) { source in
                NavigationLink {
                    ArticlesView(viewModel: articlesViewModel(source))
                } label: {
                    SourceRowView(source: source)
                }
                .accessibilityIdentifier("source.row.\(source.id)")
            }
        }
        .listStyle(.insetGrouped)
        .accessibilityIdentifier("sources.list")
    }
}

private struct SourceRowView: View {
    let source: NewsSource

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(source.name)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(2)

            Text(source.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .padding(.vertical, AppSpacing.xs)
        .accessibilityElement(children: .combine)
    }
}
