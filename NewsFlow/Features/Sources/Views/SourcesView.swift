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
            sourcesSkeleton
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
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                            .padding(.horizontal, AppSpacing.md)
                            .frame(height: 36)
                            .foregroundColor(isSelected ? .white : AppPalette.softBlue)
                            .background(isSelected ? AppPalette.softBlue : AppPalette.elevatedBackground)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(isSelected ? Color.clear : AppPalette.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(viewModel.localizedCategory(category))
                    .accessibilityIdentifier("category.chip.\(category)")
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
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(alignment: .firstTextBaseline) {
                Text(source.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Spacer(minLength: AppSpacing.sm)

                Text(category)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(AppPalette.softBlue)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xxs)
                    .background(AppPalette.softBlue.opacity(0.1))
                    .clipShape(Capsule())
            }

            Text(source.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .padding(.vertical, AppSpacing.xs)
        .accessibilityElement(children: .combine)
    }
}
