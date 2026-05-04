import SwiftUI

// MARK: - SourcesView

/// The main entry point for browsing news sources.
/// Displays sources in a Netflix-style horizontal scrolling layout,
/// grouped by category with large visual cards.
struct SourcesView: View {
    @StateObject private var viewModel: SourcesViewModel
    @EnvironmentObject private var router: AppRouter
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

    // MARK: - Content States

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            sourcesSkeleton
                .transition(.opacity)

        case .loaded:
            sourceList
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.97)),
                    removal: .opacity
                ))

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

    // MARK: - Source List (Netflix Style)

    private var sourceList: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // App branding header with staggered animation
                appHeader
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.sm)
                    .padding(.bottom, AppSpacing.lg)

                // Horizontal category filter chips
                CategoryFilterView(viewModel: viewModel)
                    .padding(.bottom, AppSpacing.lg)

                // Grouped horizontal rows — one per category
                ForEach(Array(viewModel.groupedSources.enumerated()), id: \.element.category) { index, group in
                    CategoryRowView(
                        category: viewModel.localizedCategory(group.category),
                        sources: group.sources,
                        articlesViewModel: articlesViewModel
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

    // MARK: - App Header

    private var appHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "newspaper.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppPalette.primaryRed)

                Text("NewsFlow")
                    .font(.system(size: 34, weight: .black, design: .serif))
                    .foregroundColor(AppPalette.textPrimary)
            }

            Text("Discover trusted sources from around the world")
                .font(.subheadline.weight(.medium))
                .foregroundColor(AppPalette.textSecondary)
                .lineLimit(2)
        }
    }

    // MARK: - Skeleton

    private var sourcesSkeleton: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                // Header skeleton
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    ShimmerLine(width: 200, height: 40)
                    ShimmerLine(width: 280, height: 18)
                }
                .padding(.horizontal, AppSpacing.md)

                // Chips skeleton
                HStack(spacing: AppSpacing.sm) {
                    ForEach(0..<4, id: \.self) { _ in
                        ShimmerLine(width: 72, height: 36)
                    }
                }
                .padding(.horizontal, AppSpacing.md)

                // Rows skeleton
                ForEach(0..<3, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        ShimmerLine(width: 120, height: 20)
                        HStack(spacing: AppSpacing.md) {
                            ForEach(0..<3, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: AppRadius.lg)
                                    .fill(Color(.tertiarySystemFill))
                                    .frame(width: 140, height: 160)
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

/// Horizontal scrolling filter chips at the top of the sources screen.
/// Tapping a category filters the rows below to show only that category.
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
                            .categoryChip(isSelected: isSelected)
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

/// A single horizontal row representing one category.
/// Contains a header title and a horizontally scrollable list of source cards.
struct CategoryRowView: View {
    let category: String
    let sources: [NewsSource]
    let articlesViewModel: (NewsSource) -> ArticlesViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Row header with red accent bar
            HStack(spacing: AppSpacing.sm) {
                Rectangle()
                    .fill(AppPalette.primaryRed)
                    .frame(width: 4, height: 18)
                    .clipShape(RoundedRectangle(cornerRadius: 2))

                Text(category)
                    .font(.system(size: 18, weight: .black, design: .serif))
                    .foregroundColor(AppPalette.textPrimary)

                Spacer()
            }
            .padding(.horizontal, AppSpacing.md)

            // Horizontal scrolling cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    ForEach(Array(sources.enumerated()), id: \.element.id) { index, source in
                        NavigationLink {
                            ArticlesView(viewModel: articlesViewModel(source))
                        } label: {
                            SourceMediaCard(source: source, category: category)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("source.card.\(source.id)")
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.9)),
                            removal: .opacity
                        ))
                        .animation(
                            .spring(response: 0.45, dampingFraction: 0.7)
                            .delay(Double(index) * 0.05),
                            value: sources.count
                        )
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

/// A large visual card representing a single news source.
/// Designed to feel like a Netflix content tile — big, bold, and tappable.
struct SourceMediaCard: View {
    let source: NewsSource
    let category: String

    /// Deterministic background color based on source name hash.
    /// Same source always gets the same color, making the UI feel consistent.
    private var cardColor: Color {
        let colors: [Color] = [
            Color(red: 0.85, green: 0.20, blue: 0.20),
            Color(red: 0.20, green: 0.45, blue: 0.85),
            Color(red: 0.20, green: 0.65, blue: 0.35),
            Color(red: 0.75, green: 0.55, blue: 0.15),
            Color(red: 0.55, green: 0.25, blue: 0.75),
            Color(red: 0.85, green: 0.45, blue: 0.20),
            Color(red: 0.20, green: 0.70, blue: 0.75),
            Color(red: 0.65, green: 0.20, blue: 0.35)
        ]
        let hash = abs(source.name.hashValue)
        return colors[hash % colors.count]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Large colored tile with initials
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .fill(cardColor.opacity(0.15))
                    .frame(width: 140, height: 160)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                            .stroke(cardColor.opacity(0.25), lineWidth: 1.5)
                    )

                VStack(spacing: AppSpacing.xs) {
                    ZStack {
                        Circle()
                            .fill(cardColor)
                            .frame(width: 56, height: 56)
                            .shadow(color: cardColor.opacity(0.35), radius: 8, x: 0, y: 4)

                        Text(String(source.name.prefix(1)))
                            .font(.system(size: 28, weight: .black, design: .serif))
                            .foregroundColor(.white)
                    }

                    Text(source.name)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppPalette.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(width: 120)
                }
            }

            // Category pill below the card
            Text(category)
                .font(.system(size: 10, weight: .black))
                .tracking(0.5)
                .foregroundColor(cardColor)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xxs)
                .background(cardColor.opacity(0.12))
                .clipShape(Capsule())
                .padding(.top, AppSpacing.xs)
        }
        .contentShape(Rectangle())
    }
}
