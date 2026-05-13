import SwiftUI

struct SourcesView: View {
    @StateObject private var viewModel: SourcesViewModel
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
            AppPalette.background.ignoresSafeArea()
            content
        }
        .navigationTitle(L10n.text("sources.title"))
        .navigationBarTitleDisplayMode(.large)
        .task { await viewModel.load() }
        .offlineAware()
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
                systemImage: "square.grid.2x2",
                title: L10n.text("sources.empty.title"),
                message: L10n.text("sources.empty.message")
            )
            .transition(.opacity)
        }
    }

    private var sourceList: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                sectionHeader
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
        .refreshable { await viewModel.refresh() }
        .accessibilityIdentifier("sources.list")
    }

    private var sectionHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            HStack(spacing: AppSpacing.sm) {
                Circle()
                    .fill(AppPalette.accent)
                    .frame(width: 8, height: 8)
                Text(L10n.text("sources.title").uppercased())
                    .font(AppTypography.small.weight(.bold))
                    .foregroundColor(AppPalette.accent)
            }

            Text("> \(viewModel.sources.count) SOURCES AVAILABLE")
                .font(AppTypography.monoSmall)
                .foregroundColor(AppPalette.textTertiary)

            Rectangle()
                .fill(AppPalette.borderLight)
                .frame(height: 1)
                .padding(.top, AppSpacing.sm)
        }
    }
}

#if DEBUG
#if !CODEX_DISABLE_PREVIEWS
#Preview("Sources - Loaded") {
    NavigationView {
        SourcesView(
            viewModel: SourcesViewModel(fetchUseCase: FetchSourcesUseCase(repository: MockSourcesRepository(sources: NewsFixture.sources))),
            articlesViewModel: { _ in NewsFixture.previewViewModel() }
        )
    }
}

#Preview("Sources - Loading") {
    NavigationView {
        SourcesView(
            viewModel: SourcesViewModel(fetchUseCase: FetchSourcesUseCase(repository: MockSourcesRepository(sources: []))),
            articlesViewModel: { _ in NewsFixture.previewViewModel() }
        )
    }
}
#endif

#endif
