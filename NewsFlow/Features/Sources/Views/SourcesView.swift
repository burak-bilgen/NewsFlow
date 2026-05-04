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
                    Image(systemName: "gearshape")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppPalette.primaryRed)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(AppPalette.primaryRedMuted)
                        )
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
            sourcesSkeleton
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
            Text("NEWSFLOW")
                .font(.system(size: 42, weight: .black, design: .serif))
                .tracking(4)
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

                Text("Trusted Sources Worldwide")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppPalette.textSecondary)
            }
            .padding(.top, AppSpacing.xxs)
        }
    }

    // MARK: - Skeleton

    private var sourcesSkeleton: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                VStack(spacing: AppSpacing.sm) {
                    ShimmerLine(width: 280, height: 50)
                    ShimmerLine(width: 200, height: 3)
                    ShimmerLine(width: 180, height: 14)
                }
                .padding(.horizontal, AppSpacing.md)

                HStack(spacing: AppSpacing.sm) {
                    ForEach(0..<4, id: \.self) { _ in
                        ShimmerLine(width: 72, height: 36)
                    }
                }
                .padding(.horizontal, AppSpacing.md)

                ForEach(0..<3, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        ShimmerLine(width: 120, height: 20)
                        HStack(spacing: AppSpacing.md) {
                            ForEach(0..<3, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: AppRadius.md)
                                    .fill(Color(.tertiarySystemFill))
                                    .frame(width: 120, height: 140)
                                    .modifier(ShimmerEffect())
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                }
            }
            .padding(.vertical, AppSpacing.lg)
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

// MARK: - Category Filter

struct CategoryFilterView: View {
    @ObservedObject var viewModel: SourcesViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(viewModel.categories, id: \.self) { category in
                    let isSelected = viewModel.selectedCategories.contains(category)
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.toggleCategory(category)
                        }
                        Haptic.light()
                    } label: {
                        Text(viewModel.localizedCategory(category))
                            .font(.system(size: 13, weight: .bold))
                            .tracking(0.5)
                            .lineLimit(1)
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.xs)
                            .foregroundColor(isSelected ? .white : AppPalette.primaryRed)
                            .background(isSelected ? AppPalette.primaryRed : Color.clear)
                            .overlay(
                                Capsule()
                                    .stroke(AppPalette.primaryRed, lineWidth: 1.5)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(isSelected ? 1.05 : 1.0)
                    .accessibilityLabel(viewModel.localizedCategory(category))
                    .accessibilityIdentifier("category.chip.\(category)")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(.horizontal, AppSpacing.md)
        }
    }
}

// MARK: - Category Row

struct CategoryRowView: View {
    let category: String
    let sources: [NewsSource]
    let articlesViewModel: (NewsSource) -> ArticlesViewModel
    var heroNamespace: Namespace.ID?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Section header with underline
            HStack(spacing: AppSpacing.sm) {
                Text(category.uppercased())
                    .font(.system(size: 16, weight: .black, design: .serif))
                    .tracking(1)
                    .foregroundColor(AppPalette.textPrimary)

                Rectangle()
                    .fill(AppPalette.primaryRed)
                    .frame(height: 2)

                Spacer()
            }
            .padding(.horizontal, AppSpacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    ForEach(Array(sources.enumerated()), id: \.element.id) { index, source in
                        NavigationLink {
                            ArticlesView(
                                viewModel: articlesViewModel(source),
                                heroNamespace: heroNamespace
                            )
                        } label: {
                            SourceMediaCard(source: source, heroNamespace: heroNamespace)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("source.card.\(source.id)")
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
            }
        }
        .padding(.bottom, AppSpacing.lg)
    }
}

// MARK: - Source Media Card

struct SourceMediaCard: View {
    let source: NewsSource
    var heroNamespace: Namespace.ID?

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            // Logo or fallback initials
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(Color(.tertiarySystemBackground))
                    .frame(width: 120, height: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                            .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                    )

                if let logoURL = source.logoURL {
                    AsyncImage(url: logoURL) { phase in
                        switch phase {
                        case let .success(image):
                            image
                                .resizable()
                                .scaledToFit()
                                .padding(AppSpacing.md)
                        case .failure, .empty:
                            fallbackInitials
                        @unknown default:
                            fallbackInitials
                        }
                    }
                    .frame(width: 120, height: 120)
                } else {
                    fallbackInitials
                }
            }
            .ifLet(heroNamespace) { view, ns in
                view.matchedGeometryEffect(id: "source.\(source.id)", in: ns)
            }

            Text(source.name)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(AppPalette.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 120)
        }
        .contentShape(Rectangle())
    }

    private var fallbackInitials: some View {
        Text(String(source.name.prefix(1)))
            .font(.system(size: 40, weight: .black, design: .serif))
            .foregroundColor(AppPalette.primaryRed)
            .frame(width: 120, height: 120)
    }
}

// Helper for optional matchedGeometryEffect
extension View {
    @ViewBuilder
    func ifLet<T, Content: View>(_ value: T?, transform: (Self, T) -> Content) -> some View {
        if let value {
            transform(self, value)
        } else {
            self
        }
    }
}
