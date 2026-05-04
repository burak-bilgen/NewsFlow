import SwiftUI

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
        }
        .padding(.bottom, AppSpacing.lg)
    }
}
