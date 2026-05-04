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
            sourcesSkeleton
                .transition(.opacity)
        case .loaded:
            sourceList
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
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
                ForEach(viewModel.visibleSources) { source in
                    NavigationLink {
                        ArticlesView(viewModel: articlesViewModel(source))
                    } label: {
                        SourceRowView(source: source, category: viewModel.localizedCategory(source.category))
                    }
                    .accessibilityIdentifier("source.row.\(source.id)")
                }
            }
        }
        .listStyle(.insetGrouped)
        .animation(.easeInOut(duration: 0.2), value: viewModel.visibleSources)
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

private struct CategoryFilterView: View {
    @ObservedObject var viewModel: SourcesViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(viewModel.categories, id: \.self) { category in
                    let isSelected = viewModel.selectedCategories.contains(category)
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.toggleCategory(category)
                        }
                        Haptic.light()
                    } label: {
                        Text(viewModel.localizedCategory(category))
                            .categoryChip(isSelected: isSelected)
                    }
                    .buttonStyle(.plain)
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

private struct SourceRowView: View {
    let source: NewsSource
    let category: String

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(AppPalette.primaryRed.opacity(0.1))
                    .frame(width: 52, height: 52)

                Text(String(source.name.prefix(1)))
                    .font(.title2.weight(.bold))
                    .foregroundColor(AppPalette.primaryRed)
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack(alignment: .firstTextBaseline) {
                    Text(source.name)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(AppPalette.textPrimary)
                        .lineLimit(1)

                    Spacer(minLength: AppSpacing.sm)

                    Text(category)
                        .font(.caption2.weight(.bold))
                        .foregroundColor(AppPalette.primaryRed)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xxs)
                        .background(AppPalette.primaryRed.opacity(0.1))
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
