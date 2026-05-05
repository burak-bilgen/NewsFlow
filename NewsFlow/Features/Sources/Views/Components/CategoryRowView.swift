import SwiftUI

// MARK: - Category Row

struct CategoryRowView: View {
    let category: String
    let sources: [NewsSource]
    let articlesViewModel: (NewsSource) -> ArticlesViewModel
    var heroNamespace: Namespace.ID?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Newspaper-style section header
            HStack(spacing: AppSpacing.sm) {
                Text(category.uppercased())
                    .font(.system(size: 15, weight: .black, design: .serif))

                    .foregroundColor(AppPalette.textPrimary)

                Rectangle()
                    .fill(AppPalette.textPrimary.opacity(0.2))
                    .frame(height: 1)

                Spacer()
            }
            .padding(.horizontal, AppSpacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    ForEach(sources) { source in
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

            // Thin separator between sections
            Rectangle()
                .fill(AppPalette.textPrimary.opacity(0.08))
                .frame(height: 1)
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.sm)
        }
        .padding(.bottom, AppSpacing.lg)
    }
}

#if DEBUG
#Preview {
    CategoryRowView(
        category: "General",
        sources: NewsFixture.sources,
        articlesViewModel: { _ in NewsFixture.previewViewModel() }
    )
}
#endif
