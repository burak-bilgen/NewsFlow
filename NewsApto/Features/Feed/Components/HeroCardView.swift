import SwiftUI

struct HeroCardView: View {
    let article: Article
    let onSelect: () -> Void
    let onToggle: () -> Void
    let isSaved: Bool

    var body: some View {
        Button { onSelect() } label: {
            ZStack(alignment: .bottomLeading) {
                ArticleImageView(url: article.imageURL)
                    .frame(height: 320)
                    .clipped()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 8) {
                    // Badges row at top
                    if !article.badges.isEmpty {
                        ArticleBadgeView(badges: article.badges, size: .medium)
                            .padding(.bottom, 4)
                    }
                    
                    Text(article.sourceName.uppercased())
                        .font(AppTypography.small.weight(.bold))
                        .foregroundColor(AppPalette.accent)

                    Text(article.title)
                        .font(AppTypography.largeTitle)
                        .foregroundColor(.white)
                        .lineLimit(3)

                    if let desc = article.description, !desc.isEmpty {
                        Text(desc)
                            .font(AppTypography.body)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(2)
                    }
                    
                    // Curation reason
                    if let reason = article.curationReason {
                        Text(reason.reason)
                            .font(AppTypography.monoSmall)
                            .foregroundColor(AppPalette.accent)
                            .padding(.top, 4)
                    }
                    
                    // Score indicator
                    if let score = article.qualityScore {
                        HStack(spacing: 4) {
                            Text("> QUALITY: \(Int(score))/100")
                                .font(AppTypography.monoTiny)
                                .foregroundColor(AppPalette.accent.opacity(0.9))
                        }
                    }
                }
                .padding(16)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture().onEnded {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        )
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
