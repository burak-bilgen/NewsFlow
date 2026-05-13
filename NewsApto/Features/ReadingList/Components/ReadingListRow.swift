import SwiftUI

struct ReadingListRow: View {
    let article: Article
    let onSelect: () -> Void
    let onRemove: () -> Void
    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onSelect) {
                HStack(spacing: 12) {
                    ArticleImageView(url: article.imageURL)
                        .frame(width: 72, height: 72)
                        .clipped()
                        .overlay(Rectangle().stroke(AppPalette.cardBorder, lineWidth: 0.5))

                    VStack(alignment: .leading, spacing: 4) {
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
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onRemove()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppPalette.accent)
                    .frame(width: 44, height: 44)
                    .overlay(Rectangle().stroke(AppPalette.accent.opacity(0.3), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 8)
        .onAppear {
            withAnimation(AppAnimation.reveal) { isVisible = true }
        }
    }
}

#if DEBUG
#if !CODEX_DISABLE_PREVIEWS
#Preview {
    ZStack {
        AppPalette.background.ignoresSafeArea()
        ReadingListRow(
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
            onRemove: {}
        )
        .padding()
    }
}
#endif
#endif
