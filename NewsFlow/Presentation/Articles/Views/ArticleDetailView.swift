import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    let sourceName: String
    var isSaved: Bool = false
    var onToggleReadingList: (() -> Void)?
    var heroNamespace: Namespace.ID? = nil
    @State private var showSafari = false
    @State private var appearAnimation = false
    @State private var showSummary = false
    @State private var summary: String?
    @State private var isSummarizing = false
    @ObservedObject private var ttsService = TextToSpeechService.shared

    private let intelligence = IntelligenceFactory.make()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                heroSection

                contentSection
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, -AppSpacing.xl)
            }
            .padding(.bottom, AppSpacing.xl)
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(AppPalette.screenBackground)
        .onAppear {
            appearAnimation = true
            ReadArticlesTracker.shared.markAsReadNonisolated(article.id)
        }
    }

    private var heroSection: some View {
        ZStack(alignment: .topTrailing) {
            if let url = article.imageURL {
                ArticleImageView(url: url)
                    .frame(maxWidth: .infinity, minHeight: 300, idealHeight: 320, maxHeight: 340)
                    .overlay(
                        LinearGradient(
                            colors: [AppPalette.gradientDark, AppPalette.gradientMid, AppPalette.gradientClear],
                            startPoint: .bottom, endPoint: .top
                        )
                    )
            } else {
                Rectangle()
                    .fill(AppPalette.brandPrimaryMuted)
                    .frame(maxWidth: .infinity, minHeight: 200, idealHeight: 240, maxHeight: 260)
                    .overlay(
                        Image(systemName: "newspaper")
                            .font(.system(size: 48))
                            .foregroundColor(AppPalette.brandPrimary.opacity(0.3))
                    )
            }

            if let onToggle = onToggleReadingList {
                ReadingListToggleButton(
                    isSaved: isSaved,
                    displayStyle: .hero,
                    action: onToggle
                )
                .padding(AppSpacing.md)
            }

            VStack {
                Spacer()
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(sourceName.uppercased())
                        .font(AppTypography.badge.font)
                        .foregroundColor(AppPalette.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppPalette.accentMuted)
                        .clipShape(Capsule())

                    Text(article.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .lineSpacing(4)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                .padding(AppSpacing.lg)
            }
        }
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(article.displayDate)
                    .font(AppTypography.caption.font)
                    .foregroundColor(AppPalette.textTertiary)

                if let description = article.description {
                    Text(description)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(AppPalette.textPrimary)
                        .lineSpacing(6)
                }

                HStack(spacing: AppSpacing.xs) {
                    Text(article.displayDate)
                        .font(AppTypography.caption.font)
                        .foregroundColor(AppPalette.textTertiary)

                    if article.estimatedReadingMinutes > 0 {
                        Circle()
                            .fill(AppPalette.textTertiary)
                            .frame(width: 3, height: 3)
                        Text(article.readingTimeDisplay)
                            .font(AppTypography.caption.font)
                            .foregroundColor(AppPalette.textTertiary)
                    }
                }
            }

            aiSummaryButton

            if let summary {
                aiSummaryCard(summary)
            }

            if let snippet = article.contentSnippet {
                Text(snippet)
                    .font(AppTypography.body.font)
                    .foregroundColor(AppPalette.textSecondary)
                    .lineSpacing(4)
            }

            listenButton

            if let url = article.url {
                Button {
                    showSafari = true
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "safari")
                            .font(.system(size: 18))
                        Text(L10n.text("article.readFull"))
                            .font(.system(size: 16, weight: .semibold))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.md)
                    .background(AppPalette.brandPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showSafari) {
                    SafariView(url: url)
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(AppPalette.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
        .shadow(color: AppPalette.shadowColor, radius: 8, x: 0, y: 2)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.1), value: appearAnimation)
    }

    @ViewBuilder
    private var aiSummaryButton: some View {
        if summary == nil {
            Button {
                generateSummary()
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    if isSummarizing {
                        ProgressView()
                            .tint(AppPalette.brandPrimary)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "sparkle.magnifyingglass")
                            .font(.system(size: 15))
                    }
                    Text(isSummarizing ? L10n.text("article.summarizing") : L10n.text("article.summarize"))
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    if intelligence.availability.isAvailable {
                        Image(systemName: "sparkle")
                            .font(.system(size: 10))
                            .foregroundColor(AppPalette.accent)
                    }
                }
                .foregroundColor(AppPalette.brandPrimary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(AppPalette.brandPrimaryMuted)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            }
            .disabled(isSummarizing)
            .buttonStyle(.plain)
        }
    }

    private func aiSummaryCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "sparkle")
                    .font(.system(size: 12))
                    .foregroundColor(AppPalette.accent)
                Text(L10n.text("article.summary.title"))
                    .font(AppTypography.sectionTitle.font)
                    .foregroundColor(AppPalette.accent)
                Spacer()
                if intelligence.availability.isAvailable {
                    Text("iOS 18+")
                        .font(AppTypography.badge.font)
                        .foregroundColor(AppPalette.success)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppPalette.success.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            Text(text)
                .font(AppTypography.body.font)
                .foregroundColor(AppPalette.textPrimary)
                .lineSpacing(4)
        }
        .padding(AppSpacing.md)
        .background(AppPalette.brandPrimaryMuted.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .stroke(AppPalette.accent.opacity(0.2), lineWidth: 1)
        )
    }

    private var listenButton: some View {
        let isPlayingThis = ttsService.currentArticleID == article.id && ttsService.isPlaying
        let isPausedThis = ttsService.currentArticleID == article.id && ttsService.isPaused
        let iconName: String = isPlayingThis ? "pause.circle.fill" : isPausedThis ? "play.circle.fill" : "ear.fill"
        let labelText: String = isPlayingThis ? L10n.text("article.tts.pause") : isPausedThis ? L10n.text("article.tts.resume") : L10n.text("article.tts.listen")

        return Button {
            let text = [article.title, article.description, article.contentSnippet]
                .compactMap { $0 }
                .joined(separator: ". ")
            if ttsService.currentArticleID == article.id {
                ttsService.toggle()
            } else {
                ttsService.speak(text, articleID: article.id)
            }
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: iconName)
                    .font(.system(size: 15))
                Text(labelText)
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                if isPlayingThis {
                    HStack(spacing: 3) {
                        ForEach(0..<3) { i in
                            AudioWaveBar(index: i)
                        }
                    }
                    .frame(height: 16)
                }
            }
            .foregroundColor(AppPalette.success)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(AppPalette.success.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func generateSummary() {
        isSummarizing = true
        Task {
            let text = [article.title, article.description, article.contentSnippet]
                .compactMap { $0 }
                .joined(separator: ". ")
            let result = await intelligence.generateSummary(for: text)
            await MainActor.run {
                summary = result
                isSummarizing = false
                if result != nil { Haptic.success() }
            }
        }
    }
}

private struct AudioWaveBar: View {
    let index: Int
    @State private var height: CGFloat = 4

    private var animationDelay: Double { Double(index) * 0.15 }

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(AppPalette.success)
            .frame(width: 3, height: height)
            .animation(
                .easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(animationDelay),
                value: height
            )
            .onAppear {
                height = [12, 16, 8][index]
            }
    }
}

#if DEBUG
#Preview {
    NavigationView {
        ArticleDetailView(
            article: NewsFixture.articlesBySource["bbc-news"]![0],
            sourceName: "BBC News"
        )
    }
}
#endif
