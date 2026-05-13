import SwiftUI

struct HeroDetailView: View {
    let article: Article; let isSaved: Bool; let onToggle: () -> Void; let onDismiss: () -> Void

    @State private var showContent = false
    @State private var imageBlur: CGFloat = 8
    @State private var contentOffset: CGFloat = 24
    @State private var showSafari = false
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false

    private let swipeThreshold: CGFloat = 100
    private let swipeVelocity: CGFloat = 500

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
                            if let snippet = article.distinctContentSnippet {
                                Rectangle().fill(AppPalette.dividerBorder).frame(height: 0.5).padding(.vertical, 4)
                                Text("> ARTICLE CONTEXT").font(AppTypography.monoSmall).foregroundColor(AppPalette.accent)
                                Text(snippet).font(AppTypography.body).foregroundColor(AppPalette.textPrimary).lineSpacing(5).padding(.leading, 12)
                                    .overlay(Rectangle().fill(AppPalette.accent.opacity(0.3)).frame(width: 2), alignment: .leading)
                            }
                            if article.url != nil {
                                Rectangle().fill(AppPalette.dividerBorder).frame(height: 0.5).padding(.vertical, 4)
                                HStack {
                                    Button { showSafari = true } label: {
                                        HStack { Text("> READ ORIGINAL").font(AppTypography.monoSmall).foregroundColor(.black) }
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
            .offset(x: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width > 0 {
                            dragOffset = value.translation.width
                            isDragging = true
                        }
                    }
                    .onEnded { value in
                        let velocity = value.predictedEndLocation.x - value.location.x
                        let translation = value.translation.width

                        if translation > swipeThreshold || velocity > swipeVelocity {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.easeOut(duration: 0.25)) {
                                dragOffset = UIScreen.main.bounds.width
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                onDismiss()
                            }
                        } else {
                            withAnimation(.easeOut(duration: 0.2)) {
                                dragOffset = 0
                            }
                        }
                        isDragging = false
                    }
            )

            // Swipe indicator on left edge
            if isDragging && dragOffset > 20 {
                HStack {
                    VStack(spacing: 8) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppPalette.accent)
                        Text("> SWIPE")
                            .font(AppTypography.monoTiny)
                            .foregroundColor(AppPalette.accent)
                    }
                    .frame(width: 60)
                    .padding(.leading, 20)
                    Spacer()
                }
                .padding(.top, 100)
                .allowsHitTesting(false)
            }

            VStack {
                HStack(spacing: 8) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(AppAnimation.reveal) { onDismiss() }
                    } label: {
                        Image(systemName: "chevron.left").font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppPalette.accent)
                            .frame(width: 44, height: 44)
                            .background(AppPalette.background)
                            .overlay(Rectangle().stroke(AppPalette.accent, lineWidth: 1))
                    }
                    Spacer()
                    Button {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        onToggle()
                    } label: {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(isSaved ? AppPalette.background : AppPalette.accent)
                            .frame(width: 44, height: 44)
                            .background(isSaved ? AppPalette.accent : AppPalette.background)
                            .overlay(Rectangle().stroke(AppPalette.accent, lineWidth: 1))
                    }
                }
                .padding(.horizontal, 12).padding(.top, 56)
                Spacer()
            }
        }
        .onAppear {
            withAnimation(AppAnimation.reveal) { imageBlur = 0 }
            withAnimation(AppAnimation.transition.delay(0.15)) { showContent = true; contentOffset = 0 }
        }
        .sheet(isPresented: $showSafari) {
            if let url = article.url {
                SafariView(url: url)
            }
        }
        .statusBarHidden(true)
    }
}
