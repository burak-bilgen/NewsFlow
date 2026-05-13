import SwiftUI

struct ArticleHeroCard: View {
    let article: Article
    let sourceName: String
    var heroNamespace: Namespace.ID?
    var sourceID: String = ""
    let isSaved: Bool
    let onToggle: () -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            NavigationLink {
                ArticleDetailView(
                    article: article,
                    sourceName: sourceName,
                    isSaved: isSaved,
                    onToggleReadingList: onToggle
                )
            } label: {
                heroContent
            }
            .buttonStyle(.plain)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.clear, radius: 12, x: 0, y: 4)
    }

    private var heroContent: some View {
        Group {
            if let url = article.imageURL {
                if let ns = heroNamespace {
                    ArticleImageView(url: url)
                        .matchedGeometryEffect(id: "image-\(article.id)", in: ns)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay(gradientOverlay)
                        .overlay(overlayContent, alignment: .bottomLeading)
                } else {
                    ArticleImageView(url: url)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay(gradientOverlay)
                        .overlay(overlayContent, alignment: .bottomLeading)
                }
            } else {
                Rectangle()
                    .fill(AppPalette.accentMuted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(
                        Image(systemName: "newspaper")
                            .font(.system(size: 48))
                            .foregroundColor(AppPalette.accent.opacity(0.3))
                    )
                    .overlay(gradientOverlay)
                    .overlay(overlayContent, alignment: .bottomLeading)
            }
        }
    }

    private var gradientOverlay: some View {
        LinearGradient(
            colors: [Color.black.opacity(0.8), Color.black.opacity(0.4), Color.clear],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    private var overlayContent: some View {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack(spacing: AppSpacing.xs) {
                    Text(sourceName.uppercased())
                        .font(AppTypography.small)
                        .foregroundColor(AppPalette.accent)

                    Circle()
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 3, height: 3)

                    if article.estimatedReadingMinutes > 0 {
                        Text(article.readingTimeDisplay)
                            .font(AppTypography.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Circle()
                            .fill(Color.white.opacity(0.4))
                            .frame(width: 3, height: 3)
                    }

                    Text(article.displayDate)
                        .font(AppTypography.caption)
                        .foregroundColor(.white.opacity(0.7))
                }

            Text(article.title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(3)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

            if let description = article.description {
                Text(description)
                    .font(AppTypography.body)
                    .foregroundColor(.white.opacity(0.75))
                    .lineLimit(2)
            }
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if DEBUG
#if !CODEX_DISABLE_PREVIEWS
#Preview {
    ArticleHeroCard(
        article: NewsFixture.articlesBySource["bbc-news"]![0],
        sourceName: "BBC News",
        isSaved: false,
        onToggle: {}
    )
    .frame(height: 380)
    .padding()
}
#endif

#endif
