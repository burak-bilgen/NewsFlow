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
                        .background(
                            Circle()
                                .fill(AppPalette.primaryRedMuted)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .task {
            await viewModel.load()
        }
        .toastOverlay()
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

                // Newspaper footer decoration
                newspaperFooter
                    .padding(.top, AppSpacing.xl)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            .padding(.bottom, AppSpacing.xl)
        }
        .refreshable {
            await viewModel.refresh()
        }
        .accessibilityIdentifier("sources.list")
    }

    private var newspaperFooter: some View {
        VStack(spacing: AppSpacing.sm) {
            newspaperDivider
            HStack(spacing: AppSpacing.sm) {
                Text("Edition 1")
                    .font(.system(size: 10, weight: .semibold, design: .serif))
                    .foregroundColor(AppPalette.textSecondary)
                Spacer()
                Text("All Rights Reserved")
                    .font(.system(size: 10, weight: .semibold, design: .serif))
                    .foregroundColor(AppPalette.textSecondary)
            }
            newspaperDivider
        }
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: - Masthead Header (Newspaper Style)

    @ViewBuilder
    private var mastheadHeader: some View {
        VStack(spacing: 0) {
            // Top decorative line
            newspaperDivider
                .padding(.bottom, AppSpacing.sm)

            // Main masthead title with newspaper effect
            Text("NEWS FLOW")
                .font(.system(size: 40, weight: .black, design: .serif))
                .foregroundColor(AppPalette.textPrimary)
                .shadow(color: Color.black.opacity(0.15), radius: 2, x: 1, y: 1)
                .scaleEffect(1.0)
                .animation(.easeOut(duration: 0.6).delay(0.1), value: true)

            // Double-rule separator (classic newspaper)
            VStack(spacing: 2) {
                newspaperDivider
                newspaperDivider
            }
            .padding(.vertical, AppSpacing.sm)

            // Date and subtitle row
            HStack {
                Text(Date(), style: .date)
                    .font(.system(size: 11, weight: .semibold, design: .serif))
                    .foregroundColor(AppPalette.textSecondary)
                    .textCase(.uppercase)

                Spacer()

                Text(L10n.text("sources.mastheadSubtitle"))
                    .font(.system(size: 11, weight: .semibold, design: .serif))
                    .foregroundColor(AppPalette.textSecondary)
            }

            // Bottom thin rule
            newspaperDivider
                .padding(.top, AppSpacing.sm)
        }
    }

    private var newspaperDivider: some View {
        Rectangle()
            .fill(AppPalette.textPrimary.opacity(0.85))
            .frame(height: 1)
    }
}

// MARK: - Previews

#if DEBUG
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
