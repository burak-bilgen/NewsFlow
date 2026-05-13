import SwiftUI

struct MagazineListCard: View {
    let article: Article
    let isSaved: Bool
    let onToggle: () -> Void
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 12) {
                ArticleImageView(url: article.imageURL)
                    .frame(width: 80, height: 80)
                    .clipped()

                VStack(alignment: .leading, spacing: 3) {
                    Text(article.sourceName.uppercased())
                        .font(AppTypography.small.weight(.bold))
                        .foregroundColor(AppPalette.accent)

                    Text(article.title)
                        .font(AppTypography.caption.weight(.semibold))
                        .foregroundColor(AppPalette.textPrimary)
                        .lineLimit(2)

                    Text(article.displayDate)
                        .font(AppTypography.small)
                        .foregroundColor(AppPalette.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 2)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#if !CODEX_DISABLE_PREVIEWS
#Preview {
    ZStack {
        AppPalette.background.ignoresSafeArea()
        MagazineListCard(
            article: Article(
                id: "1",
                sourceID: "test",
                title: "Test Article Title",
                description: "Test description",
                imageURL: nil,
                publishedAt: Date(),
                url: nil,
                sourceName: "Test Source",
                contentSnippet: nil
            ),
            isSaved: false,
            onToggle: {},
            onSelect: {}
        )
        .padding()
    }
}
#endif
#endif
