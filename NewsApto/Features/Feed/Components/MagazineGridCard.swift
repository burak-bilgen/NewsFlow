import SwiftUI

struct MagazineGridCard: View {
    let article: Article
    let isSaved: Bool
    let onToggle: () -> Void
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 0) {
                ArticleImageView(url: article.imageURL)
                    .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120)
                    .clipped()

                VStack(alignment: .leading, spacing: 4) {
                    Text(article.sourceName.uppercased())
                        .font(AppTypography.small.weight(.bold))
                        .foregroundColor(AppPalette.accent)

                    Text(article.title)
                        .font(AppTypography.caption.weight(.semibold))
                        .foregroundColor(AppPalette.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack {
                        Text(article.displayDate)
                            .font(AppTypography.small)
                            .foregroundColor(AppPalette.textTertiary)
                        
                        Spacer()
                        
                        if let score = article.qualityScore {
                            Text(String(format: L10n.text("quality.score"), Int(score)))
                                .font(AppTypography.monoTiny)
                                .foregroundColor(AppPalette.accent.opacity(0.7))
                        }
                    }
                }
                .padding(8)
            }
            .background(AppPalette.surface)
            .overlay(Rectangle().stroke(AppPalette.cardBorder, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

#if DEBUG
#if !CODEX_DISABLE_PREVIEWS
#Preview {
    ZStack {
        AppPalette.background.ignoresSafeArea()
        MagazineGridCard(
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
