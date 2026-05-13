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
    @State private var isVisible = false

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
                HStack(alignment: .top, spacing: 14) {
                    articleThumbnail
                    articleInfo
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .contentShape(Rectangle())
            }
            .buttonStyle(SpringButtonStyle())

            VStack(spacing: 6) {
                ReadingListToggleButton(
                    isSaved: isSaved,
                    displayStyle: .card,
                    action: onToggle
                )
                shareButton
            }
            .offset(x: -6, y: 6)
        }
        .padding(14)
        .background(AppPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.clear, radius: 8, x: 0, y: 2)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 10)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3).delay(0.05)) {
                isVisible = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("article.card.\(article.id)")
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

    private var accessibilityLabel: String {
        "\(article.title), \(sourceName), \(article.displayDate)"
    }

    private var shareButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showShareSheet = true
        } label: {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(AppPalette.textTertiary)
                .frame(width: 26, height: 26)
                .background(AppPalette.surface.opacity(0.8))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Share article")
    }

    private var articleThumbnail: some View {
        ZStack(alignment: .topLeading) {
            Group {
                if let url = article.imageURL {
                    if let ns = heroNamespace {
                        ArticleImageView(url: url)
                            .matchedGeometryEffect(id: "image-\(article.id)", in: ns)
                            .frame(width: 90, height: 90)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else {
                        ArticleImageView(url: url)
                            .frame(width: 90, height: 90)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppPalette.accentMuted)
                        .frame(width: 90, height: 90)
                        .overlay(
                            Image(systemName: "newspaper")
                                .font(.system(size: 24))
                                .foregroundColor(AppPalette.accent.opacity(0.4))
                        )
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(AppPalette.borderLight, lineWidth: 1)
            )

            if !isRead {
                Circle()
                    .fill(AppPalette.accent)
                    .frame(width: 8, height: 8)
                    .padding(4)
            }
        }
    }

    private var articleInfo: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(article.title)
                .font(.system(size: 16, weight: .semibold, design: .default))
                .foregroundColor(isRead ? AppPalette.textTertiary : AppPalette.textPrimary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                Label(sourceName, systemImage: "rectangle.3.group")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppPalette.accent)

                if article.estimatedReadingMinutes > 0 {
                    Circle()
                        .fill(AppPalette.textTertiary)
                        .frame(width: 3, height: 3)

                    Label(article.readingTimeDisplay, systemImage: "clock")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppPalette.textTertiary)
                }

                Circle()
                    .fill(AppPalette.textTertiary)
                    .frame(width: 3, height: 3)

                Label(article.displayDate, systemImage: "calendar")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppPalette.textTertiary)
                    .labelStyle(.titleOnly)
            }
        }
        .padding(.vertical, 4)
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
