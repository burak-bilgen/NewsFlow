import SwiftUI

struct ArticleCardView: View {
    let article: Article
    let sourceName: String
    let isSaved: Bool
    let onToggle: () -> Void
    @State private var isPressed = false

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            NavigationLink {
                ArticleDetailView(article: article, sourceName: sourceName)
            } label: {
                HStack(alignment: .top, spacing: AppSpacing.md) {
                    articlePreview
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            ReadingListToggleButton(
                isSaved: isSaved,
                displayStyle: .card,
                action: onToggle
            )
            .padding(.top, AppSpacing.xs)
        }
        .padding(AppSpacing.md)
        .background(AppPalette.elevatedBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .shadow(color: AppPalette.shadowColor, radius: 12, x: 0, y: 5)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }

    private var articlePreview: some View {
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
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .lineLimit(3)
                    .foregroundColor(AppPalette.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                Spacer(minLength: 0)

                Text(article.displayDate)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(AppPalette.textSecondary)
            }
            .padding(.vertical, AppSpacing.xs)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(article.title), \(article.displayDate)")
    }
}

#if DEBUG
#Preview {
    ArticleCardView(
        article: NewsFixture.articlesBySource["bbc-news"]![1],
        sourceName: "BBC News",
        isSaved: false,
        onToggle: {}
    )
    .padding()
}
#endif
