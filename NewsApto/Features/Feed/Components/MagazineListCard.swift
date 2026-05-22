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

                VStack(alignment: .leading, spacing: 4) {
                    Text(article.sourceName.uppercased())
                        .font(AppTypography.small.weight(.bold))
                        .foregroundColor(AppPalette.accent)
                        .lineLimit(1)
                    
                    Text(article.title)
                        .font(AppTypography.headline)
                        .foregroundColor(AppPalette.textPrimary)
                        .lineLimit(3)
                    
                    if let desc = article.description, !desc.isEmpty {
                        Text(desc)
                            .font(AppTypography.caption)
                            .foregroundColor(AppPalette.textSecondary)
                            .lineLimit(2)
                    }
                    
                    // Quality score indicator
                    if let score = article.qualityScore {
                        Text(String(format: L10n.text("score.label"), Int(score)))
                            .font(AppTypography.monoTiny)
                            .foregroundColor(AppPalette.accent.opacity(0.8))
                            .padding(.top, 2)
                    }
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
