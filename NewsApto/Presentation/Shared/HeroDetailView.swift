import SwiftUI

struct HeroDetailView: View {
    let article: Article; let isSaved: Bool; let onToggle: () -> Void; let onDismiss: () -> Void

    @State private var showContent = false
    @State private var imageBlur: CGFloat = 8
    @State private var contentOffset: CGFloat = 24

    var body: some View {
        ZStack {
            AppPalette.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ArticleImageView(url: article.imageURL)
                        .frame(height: 320).clipped().blur(radius: imageBlur)

                    if showContent {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(article.sourceName.uppercased())
                                .font(AppTypography.small.weight(.bold)).foregroundColor(AppPalette.accent)
                            Text(article.title)
                                .font(AppTypography.largeTitle).foregroundColor(AppPalette.textPrimary)
                                .lineSpacing(3).fixedSize(horizontal: false, vertical: true)
                            HStack(spacing: 8) {
                                Text(article.displayDate).font(AppTypography.caption).foregroundColor(AppPalette.textTertiary)
                                if article.estimatedReadingMinutes > 0 {
                                    Circle().fill(AppPalette.textTertiary).frame(width: 3, height: 3)
                                    Text(article.readingTimeDisplay).font(AppTypography.caption).foregroundColor(AppPalette.textTertiary)
                                }
                            }
                            if let desc = article.description, !desc.isEmpty {
                                Text(desc).font(AppTypography.body).foregroundColor(AppPalette.textSecondary).lineSpacing(5).fixedSize(horizontal: false, vertical: true)
                            }
                            if let snippet = article.contentSnippet, !snippet.isEmpty {
                                Rectangle().fill(AppPalette.dividerBorder).frame(height: 0.5).padding(.vertical, 4)
                                Text("> AI ANALYSIS").font(AppTypography.monoSmall).foregroundColor(AppPalette.accent)
                                Text(snippet).font(AppTypography.body).foregroundColor(AppPalette.textPrimary).lineSpacing(5).padding(.leading, 12)
                                    .overlay(Rectangle().fill(AppPalette.accent.opacity(0.3)).frame(width: 2), alignment: .leading)
                            }
                            if let url = article.url {
                                Rectangle().fill(AppPalette.dividerBorder).frame(height: 0.5).padding(.vertical, 4)
                                HStack {
                                    Button { UIApplication.shared.open(url) } label: {
                                        HStack { Text("> OPEN IN BROWSER").font(AppTypography.monoSmall).foregroundColor(.black) }
                                            .padding(.horizontal, 16).padding(.vertical, 10).background(AppPalette.accent)
                                    }.buttonStyle(.plain)
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 40)
                        .offset(y: contentOffset)
                    }
                }
            }
            .scrollIndicators(.hidden)

            VStack {
                HStack(spacing: 8) {
                    Button { withAnimation(.easeOut(duration: 0.15)) { onDismiss() } } label: {
                        Image(systemName: "chevron.left").font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppPalette.accent)
                            .frame(width: 40, height: 40)
                            .background(AppPalette.background)
                            .overlay(Rectangle().stroke(AppPalette.accent, lineWidth: 1))
                    }
                    Spacer()
                    Button(action: onToggle) {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(isSaved ? AppPalette.background : AppPalette.accent)
                            .frame(width: 40, height: 40)
                            .background(isSaved ? AppPalette.accent : AppPalette.background)
                            .overlay(Rectangle().stroke(AppPalette.accent, lineWidth: 1))
                    }
                }
                .padding(.horizontal, 12).padding(.top, 56)
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) { imageBlur = 0 }
            withAnimation(springAnimation().delay(0.15)) { showContent = true; contentOffset = 0 }
        }
    }
}
