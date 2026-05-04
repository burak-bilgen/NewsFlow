import SwiftUI

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

    private var sourceList: some View {
        List {
            Section {
                CategoryFilterView(viewModel: viewModel)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            Section {
                ForEach(Array(viewModel.visibleSources.enumerated()), id: \.element.id) { index, source in
                    NavigationLink {
                        ArticlesView(viewModel: articlesViewModel(source))
                    } label: {
                        SourceRowView(source: source, category: viewModel.localizedCategory(source.category))
                    }
                    .accessibilityIdentifier("source.row.\(source.id)")
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity
                    ))
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.8)
                        .delay(Double(index) * 0.04),
                        value: viewModel.visibleSources
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
        .animation(.easeInOut(duration: 0.25), value: viewModel.visibleSources)
        .refreshable {
            await viewModel.refresh()
        }
        .accessibilityIdentifier("sources.list")
    }

    private var sourcesSkeleton: some View {
        List {
            Section {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(0..<4, id: \.self) { _ in
                        ShimmerLine(width: 72, height: 36)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section {
                ForEach(0..<5, id: \.self) { _ in
                    SourceRowSkeleton()
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Preview

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
            viewModel: SourcesViewModel(repository: MockSourcesRepository(sources: NewsFixture.sources)),
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
            .padding(.vertical, AppSpacing.sm)
        }
    }
}

// MARK: - Source Row

struct SourceRowView: View {
    let source: NewsSource
    let category: String

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .fill(AppPalette.primaryRed.opacity(0.08))
                    .frame(width: 56, height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                            .stroke(AppPalette.primaryRed.opacity(0.15), lineWidth: 1)
                    )

                Text(String(source.name.prefix(1)))
                    .font(.system(size: 24, weight: .black, design: .serif))
                    .foregroundColor(AppPalette.primaryRed)
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack(alignment: .firstTextBaseline) {
                    Text(source.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AppPalette.textPrimary)
                        .lineLimit(1)

                    Spacer(minLength: AppSpacing.sm)

                    Text(category)
                        .font(.system(size: 11, weight: .black))
                        .tracking(0.5)
                        .foregroundColor(AppPalette.primaryRed)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xxs)
                        .background(AppPalette.primaryRedMuted)
                        .clipShape(Capsule())
                }

                Text(source.description)
                    .font(.subheadline)
                    .foregroundColor(AppPalette.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, AppSpacing.xs)
        .accessibilityElement(children: .combine)
    }
}
