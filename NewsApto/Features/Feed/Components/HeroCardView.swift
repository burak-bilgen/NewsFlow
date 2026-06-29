import SwiftUI

struct HeroCardView: View {
    let article: Article
    let onSelect: () -> Void
    let onToggle: () -> Void
    let isSaved: Bool

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onSelect()
        } label: {
            ZStack(alignment: .bottomLeading) {
                ArticleImageView(url: article.imageURL)
                    .frame(height: 320)
                    .clipped()

                if article.imageURL != nil {
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                } else {
                    LinearGradient(
                        colors: [AppPalette.surface, AppPalette.surface.opacity(0.95)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(article.sourceName.uppercased())
                        .font(AppTypography.small.weight(.bold))
                        .foregroundColor(AppPalette.accent)

                    Text(article.title)
                        .font(AppTypography.largeTitle)
                        .foregroundColor(article.imageURL != nil ? .white : AppPalette.textPrimary)
                        .lineLimit(3)

                    if let desc = article.description, !desc.isEmpty {
                        Text(desc)
                            .font(AppTypography.body)
                            .foregroundColor(article.imageURL != nil ? .white.opacity(0.8) : AppPalette.textSecondary)
                            .lineLimit(2)
                    }
                    
                }
                .padding(16)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityLabel(article.title)
    }
}

#if DEBUG
#if !CODEX_DISABLE_PREVIEWS
#Preview {
    ZStack {
        AppPalette.background.ignoresSafeArea()
        HeroCardView(
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
            onSelect: {},
            onToggle: {},
            isSaved: false
        )
    }
}
#endif
#endif
