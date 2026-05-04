import SwiftUI

// MARK: - SourcesView

struct SourcesView: View {
    @StateObject private var viewModel: SourcesViewModel
    @EnvironmentObject private var router: AppRouter
    private let articlesViewModel: (NewsSource) -> ArticlesViewModel
    var heroNamespace: Namespace.ID?

    init(
        viewModel: SourcesViewModel,
        articlesViewModel: @escaping (NewsSource) -> ArticlesViewModel,
        heroNamespace: Namespace.ID? = nil
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.articlesViewModel = articlesViewModel
        self.heroNamespace = heroNamespace
    }

    var body: some View {
        ZStack {
            AppPalette.screenBackground.ignoresSafeArea()
            content
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppPalette.primaryRed)
                        .frame(width: 36, height: 36)
                        .background(AppPalette.primaryRedMuted)
                        .clipShape(Circle())
                }
            }
        }
        .task {
            await viewModel.load()
        }
        .accessibilityIdentifier("sources.screen")
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            SourcesSkeletonView()
                .transition(.opacity)
        case .loaded:
            sourceList
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
        case .empty:
            StateMessageView(
                systemImage: "newspaper",
                title: L10n.text("sources.empty.title"),
                message: L10n.text("sources.empty.message")
            )
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

    private var sourceList: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                mastheadHeader
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.sm)
                    .padding(.bottom, AppSpacing.lg)

                CategoryFilterView(viewModel: viewModel)
                    .padding(.bottom, AppSpacing.lg)

                ForEach(Array(viewModel.groupedSources.enumerated()), id: \.element.category) { index, group in
                    CategoryRowView(
                        category: viewModel.localizedCategory(group.category),
                        sources: group.sources,
                        articlesViewModel: articlesViewModel,
                        heroNamespace: heroNamespace
                    )
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity
                    ))
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.8)
                        .delay(Double(index) * 0.08),
                        value: viewModel.state
                    )
                }
            }
            .padding(.bottom, AppSpacing.xl)
        }
        .refreshable {
            await viewModel.refresh()
        }
        .accessibilityIdentifier("sources.list")
    }

    // MARK: - Masthead Header (Newspaper Style)

    private var mastheadHeader: some View {
        VStack(spacing: AppSpacing.xs) {
            Text("News Flow")
                .font(.system(size: 40, weight: .black, design: .serif))
                .tracking(2)
                .foregroundColor(AppPalette.primaryRed)

            Rectangle()
                .fill(AppPalette.primaryRed)
                .frame(height: 3)

            HStack {
                Text(Date(), style: .date)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppPalette.textSecondary)
                    .textCase(.uppercase)

                Spacer()

                Text(L10n.text("sources.mastheadSubtitle"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppPalette.textSecondary)
            }
            .padding(.top, AppSpacing.xxs)
        }
    }

}

// MARK: - Previews

#if DEBUG
#Preview("Sources - Loaded") {
    NavigationView {
        SourcesView(
            viewModel: SourcesViewModel(repository: MockSourcesRepository(sources: NewsFixture.sources)),
            articlesViewModel: { _ in NewsFixture.previewViewModel() }
        )
    }
}

#Preview("Sources - Loading") {
    NavigationView {
        SourcesView(
            viewModel: SourcesViewModel(repository: MockSourcesRepository(sources: [])),
            articlesViewModel: { _ in NewsFixture.previewViewModel() }
        )
    }
}
#endif
