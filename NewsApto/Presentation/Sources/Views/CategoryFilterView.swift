import SwiftUI

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
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Text(viewModel.localizedCategory(category))
                            .font(.system(size: 13, weight: .bold))
                            .lineLimit(1)
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.xs)
                            .foregroundColor(isSelected ? .white : AppPalette.accent)
                            .background(
                                Capsule()
                                    .fill(isSelected ? AppPalette.accent : AppPalette.surfaceElevated)
                            )
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
        .accessibilityIdentifier("category.filter")
    }
}

#if DEBUG
#if !CODEX_DISABLE_PREVIEWS
#Preview {
    CategoryFilterView(
        viewModel: SourcesViewModel(
            fetchUseCase: FetchSourcesUseCase(repository: MockSourcesRepository(sources: NewsFixture.sources))
        )
    )
        .padding()
}
#endif

#endif
