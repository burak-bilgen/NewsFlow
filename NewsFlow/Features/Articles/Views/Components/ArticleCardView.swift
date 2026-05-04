import SwiftUI

struct ArticleCardView: View {
    let article: Article
    let isSaved: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            ArticleImageView(url: article.imageURL)
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .stroke(AppPalette.border, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(article.title)
                    .font(.system(size: 16, weight: .bold, design: .default))
                    .lineLimit(3)
                    .foregroundColor(AppPalette.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                Spacer(minLength: 0)

                HStack {
                    Text(article.displayDate)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(AppPalette.textSecondary)

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            onToggle()
                        }
                        Haptic.light()
                    } label: {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(isSaved ? AppPalette.goldAccent : AppPalette.primaryRed)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(AppPalette.primaryRedMuted)
                            )
                            .scaleEffect(isSaved ? 1.15 : 1.0)
                    }
                }
            }
            .padding(.vertical, AppSpacing.xs)
        }
        .padding(AppSpacing.md)
        .background(AppPalette.elevatedBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .shadow(color: AppPalette.shadowColor, radius: 12, x: 0, y: 5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(article.title), \(article.displayDate)")
    }
}

#if DEBUG
#Preview {
    ArticleCardView(
        article: NewsFixture.articlesBySource["bbc-news"]![1],
        isSaved: false,
        onToggle: {}
    )
    .padding()
}
#endif
