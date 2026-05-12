import SwiftUI

struct ArticleCardView: View {
    let article: Article
    let sourceName: String
    let isSaved: Bool
    let onToggle: () -> Void
    var heroNamespace: Namespace.ID? = nil
    @State private var isPressed = false
    @State private var isRead = false
    @State private var showShareSheet = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink {
                ArticleDetailView(
                    article: article,
                    sourceName: sourceName,
                    isSaved: isSaved,
                    onToggleReadingList: onToggle,
                    heroNamespace: heroNamespace
                )
                .onAppear {
                    ReadArticlesTracker.shared.markAsReadNonisolated(article.id)
                    isRead = true
                }
            } label: {
                HStack(alignment: .top, spacing: AppSpacing.md) {
                    articleThumbnail
                    articleInfo
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            VStack(spacing: 4) {
                ReadingListToggleButton(
                    isSaved: isSaved,
                    displayStyle: .card,
                    action: onToggle
                )

                shareButton
            }
            .offset(x: -4, y: 4)
        }
        .padding(AppSpacing.md)
        .background(AppPalette.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .shadow(color: AppPalette.shadowColor, radius: 6, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animatedUnlessReducedMotion(.spring(response: 0.3, dampingFraction: 0.7))
        .accessibilityArticle(article, isSaved: isSaved)
        .accessibilityIdentifier("article.card.\(article.id)")
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .task {
            isRead = await ReadArticlesTracker.shared.isRead(article.id)
        }
        .sheet(isPresented: $showShareSheet) {
            let card = ArticleShareCard(article: article, sourceName: sourceName)
            if let image = card.renderAsImage() {
                ShareSheet(activityItems: [image, article.url as Any])
            } else {
                ShareSheet(activityItems: [article.url as Any])
            }
        }
    }

    private var shareButton: some View {
        Button {
            Haptic.light()
            showShareSheet = true
        } label: {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(AppPalette.textTertiary)
                .frame(width: 24, height: 24)
                .background(AppPalette.cardBackground.opacity(0.8))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private var articleThumbnail: some View {
        ZStack(alignment: .topLeading) {
            Group {
                if let url = article.imageURL {
                    if let ns = heroNamespace {
                        ArticleImageView(url: url)
                            .matchedGeometryEffect(id: "image-\(article.id)", in: ns)
                            .frame(width: 90, height: 90)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                    } else {
                        ArticleImageView(url: url)
                            .frame(width: 90, height: 90)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                    }
                } else {
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .fill(AppPalette.brandPrimaryMuted)
                        .frame(width: 90, height: 90)
                        .overlay(
                            Image(systemName: "newspaper")
                                .font(.system(size: 24))
                                .foregroundColor(AppPalette.brandPrimary.opacity(0.4))
                        )
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .stroke(AppPalette.border, lineWidth: 1)
            )

            if !isRead {
                Circle()
                    .fill(AppPalette.brandPrimary)
                    .frame(width: 8, height: 8)
                    .padding(4)
            }
        }
    }

    private var articleInfo: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(article.title)
                .font(AppTypography.articleTitle.font)
                .foregroundColor(isRead ? AppPalette.textTertiary : AppPalette.textPrimary)
                .lineLimit(3)

            Spacer(minLength: 0)

            HStack(spacing: AppSpacing.xs) {
                Text(sourceName)
                    .font(AppTypography.caption.font)
                    .foregroundColor(AppPalette.brandPrimary)

                if article.estimatedReadingMinutes > 0 {
                    Circle()
                        .fill(AppPalette.textTertiary)
                        .frame(width: 3, height: 3)

                    Text(article.readingTimeDisplay)
                        .font(AppTypography.caption.font)
                        .foregroundColor(AppPalette.textTertiary)
                }

                Circle()
                    .fill(AppPalette.textTertiary)
                    .frame(width: 3, height: 3)

                Text(article.displayDate)
                    .font(AppTypography.caption.font)
                    .foregroundColor(AppPalette.textTertiary)
            }
        }
        .padding(.vertical, AppSpacing.xxs)
    }
}

#if !CODEX_DISABLE_PREVIEWS
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
