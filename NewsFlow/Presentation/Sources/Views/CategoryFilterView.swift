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
                        Haptic.light()
                    } label: {
                        Text(viewModel.localizedCategory(category))
                            .font(.system(size: 13, weight: .bold))

                            .lineLimit(1)
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.xs)
                            .foregroundColor(isSelected ? .white : AppPalette.primaryRed)
                            .background(
                                Capsule()
                                    .fill(isSelected ? AppPalette.primaryRed : Color.clear)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(AppPalette.primaryRed, lineWidth: 1.5)
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
    }
}

#if DEBUG
#Preview {
    CategoryFilterView(viewModel: SourcesViewModel(fetchUseCase: FetchSourcesUseCase(repository: MockSourcesRepository(sources: NewsFixture.sources))))
        .padding()
}
#endif
