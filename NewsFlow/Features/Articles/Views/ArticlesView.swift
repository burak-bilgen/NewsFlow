import SwiftUI
import Combine

// MARK: - Main View

struct ArticlesView: View {
    @StateObject private var viewModel: ArticlesViewModel
    @State private var carouselTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    init(viewModel: ArticlesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppPalette.screenBackground.ignoresSafeArea()
            content
        }
        .navigationTitle(viewModel.source.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadIfNeeded()
            viewModel.startAutomaticRefresh()
        }
        .onDisappear {
            viewModel.stopAutomaticRefresh()
        }
        .onReceive(carouselTimer) { _ in
            advanceCarousel()
        }
        .alert(
            L10n.text("warning.title"),
            isPresented: Binding(
                get: { viewModel.warningMessage != nil },
                set: { if !$0 { viewModel.warningMessage = nil } }
            )
        ) {
            Button(L10n.text("retry.button")) {
                Task { await viewModel.retry() }
            }
            Button(L10n.text("ok.button"), role: .cancel) { }
        } message: {
            Text(viewModel.warningMessage ?? "")
        }
        .accessibilityIdentifier("articles.screen")
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ArticlesSkeletonView()
                .transition(.opacity)
        case .loaded:
            articleList
                .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.97)), removal: .opacity))
        case .empty:
            StateMessageView(
                systemImage: "doc.text.magnifyingglass",
                title: L10n.text("articles.empty.title"),
                message: L10n.text("articles.empty.message"),
                retryTitle: L10n.text("retry.button")
            ) {
                Task { await viewModel.retry() }
            }
            .transition(.opacity)
        case let .error(message):
            StateMessageView(
                systemImage: "exclamationmark.triangle",
                title: L10n.text("error.title"),
                message: message,
                retryTitle: L10n.text("retry.button")
            ) {
                Task { await viewModel.retry() }
            }
            .transition(.opacity)
        }
    }

    private var articleList: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.lg) {
                if !viewModel.featuredArticles.isEmpty {
                    FeaturedCarouselView(viewModel: viewModel)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if !viewModel.listArticles.isEmpty {
                    SectionHeaderView(title: L10n.text("articles.latest"))
                        .padding(.horizontal, AppSpacing.md)
                }

                ForEach(Array(viewModel.listArticles.enumerated()), id: \.element.id) { index, article in
                    ArticleCardView(
                        article: article,
                        isSaved: viewModel.isSaved(article)
                    ) {
                        Task { await viewModel.toggleReadingList(for: article) }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                        removal: .opacity
                    ))
                    .animation(
                        .spring(response: 0.55, dampingFraction: 0.75)
                        .delay(Double(index) * 0.05),
                        value: viewModel.state
                    )
                }
            }
            .padding(.vertical, AppSpacing.lg)
        }
        .refreshable {
            await viewModel.pullToRefresh()
        }
        .accessibilityIdentifier("articles.list")
    }

    private func advanceCarousel() {
        let count = viewModel.featuredArticles.count
        guard count > 1 else { return }
        withAnimation(Accessibility.isReduceMotionEnabled ? nil : .easeInOut(duration: 0.4)) {
            viewModel.carouselSelection = (viewModel.carouselSelection + 1) % count
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Articles - Loaded") {
    NavigationView {
        ArticlesView(viewModel: NewsFixture.previewViewModel())
    }
}

#Preview("Articles - Loading") {
    NavigationView {
        ArticlesView(viewModel: NewsFixture.previewViewModel().withState(.loading))
    }
}

#Preview("Articles - Empty") {
    NavigationView {
        ArticlesView(viewModel: NewsFixture.previewViewModel().withState(.empty))
    }
}

#Preview("Articles - Error") {
    NavigationView {
        ArticlesView(viewModel: NewsFixture.previewViewModel().withState(.error("Network connection failed")))
    }
}
#endif

// MARK: - Section Header

struct SectionHeaderView: View {
    let title: String

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Rectangle()
                .fill(AppPalette.primaryRed)
                .frame(width: 5, height: 24)
                .clipShape(RoundedRectangle(cornerRadius: 2.5))

            Text(title)
                .font(.system(size: 20, weight: .black, design: .serif))
                .foregroundColor(AppPalette.textPrimary)

            Spacer()

            Capsule()
                .fill(AppPalette.primaryRedMuted)
                .frame(width: 40, height: 4)
        }
    }
}

// MARK: - Article Card

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

// MARK: - Article Image View

struct ArticleImageView: View {
    let url: URL?
    @State private var cachedImage: Image?
    @State private var loadTask: Task<Void, Never>?
    @State private var isLoaded = false

    var body: some View {
        ZStack {
            if let cachedImage {
                cachedImage
                    .resizable()
                    .scaledToFill()
                    .opacity(isLoaded ? 1 : 0)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            isLoaded = true
                        }
                    }
            } else if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                            .opacity(isLoaded ? 1 : 0)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 0.35)) {
                                    isLoaded = true
                                }
                            }
                    case .failure, .empty:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .clipped()
        .onAppear {
            guard let url, cachedImage == nil else { return }
            loadTask = Task {
                if let uiImage = await ImageCacheService.shared.loadImage(from: url) {
                    guard !Task.isCancelled else { return }
                    cachedImage = Image(uiImage: uiImage)
                }
            }
        }
        .onDisappear {
            loadTask?.cancel()
            loadTask = nil
        }
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [AppPalette.primaryRed.opacity(0.12), Color(.tertiarySystemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "newspaper.fill")
                .font(.system(size: 32))
                .foregroundColor(AppPalette.primaryRed.opacity(0.35))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel(L10n.text("article.image.placeholder"))
    }
}

// MARK: - Featured Carousel

struct FeaturedCarouselView: View {
    @ObservedObject var viewModel: ArticlesViewModel

    var body: some View {
        GeometryReader { geometry in
            TabView(selection: $viewModel.carouselSelection) {
                ForEach(Array(viewModel.featuredArticles.enumerated()), id: \.element.id) { index, article in
                    ArticleHeroCard(
                        article: article,
                        sourceName: viewModel.source.name,
                        isSaved: viewModel.isSaved(article)
                    ) {
                        Task { await viewModel.toggleReadingList(for: article) }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .tag(index)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .tabViewStyle(.page(indexDisplayMode: .always))
        }
        .frame(height: 400)
        .accessibilityIdentifier("articles.carousel")
    }
}

// MARK: - Hero Card

struct ArticleHeroCard: View {
    let article: Article
    let sourceName: String
    let isSaved: Bool
    let onToggle: () -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ArticleImageView(url: article.imageURL)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            LinearGradient(
                colors: [
                    AppPalette.gradientStart,
                    AppPalette.gradientMid,
                    AppPalette.gradientEnd
                ],
                startPoint: .bottom,
                endPoint: .top
            )

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Text(sourceName.uppercased())
                        .font(.system(size: 11, weight: .black))
                        .tracking(1.2)
                        .foregroundColor(.white)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xxs)
                        .background(
                            Capsule()
                                .fill(AppPalette.primaryRed)
                        )

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
                            onToggle()
                        }
                        Haptic.light()
                    } label: {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(isSaved ? AppPalette.goldAccent : .white)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.35))
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .scaleEffect(isSaved ? 1.2 : 1.0)
                    }
                }

                Spacer(minLength: 60)

                Text(article.title)
                    .font(.system(size: 22, weight: .black, design: .serif))
                    .foregroundColor(.white)
                    .lineLimit(3)
                    .shadow(color: .black.opacity(0.7), radius: 4, x: 0, y: 2)

                Text(article.displayDate)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 1)
            }
            .padding(AppSpacing.lg)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
        .shadow(color: AppPalette.shadowColor, radius: 20, x: 0, y: 10)
    }
}

// MARK: - Skeleton

struct ArticlesSkeletonView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.lg) {
                ArticleHeroSkeleton()
                    .padding(.horizontal, AppSpacing.md)

                ForEach(0..<3, id: \.self) { _ in
                    ArticleRowSkeleton()
                        .padding(.horizontal, AppSpacing.md)
                }
            }
            .padding(.vertical, AppSpacing.lg)
        }
    }
}

struct ArticleRowSkeleton: View {
    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(Color(.tertiarySystemFill))
                .frame(width: 100, height: 100)
                .modifier(ShimmerEffect())

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                ShimmerLine(width: .infinity, height: 16)
                ShimmerLine(width: .infinity, height: 16)
                ShimmerLine(width: 160, height: 16)

                Spacer(minLength: 0)

                ShimmerLine(width: 80, height: 12)
            }
            .padding(.vertical, AppSpacing.xs)
        }
        .padding(AppSpacing.md)
        .background(AppPalette.elevatedBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
    }
}

struct ArticleHeroSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            RoundedRectangle(cornerRadius: AppRadius.xl)
                .fill(Color(.tertiarySystemFill))
                .frame(height: 220)
                .modifier(ShimmerEffect())

            ShimmerLine(width: .infinity, height: 22)
            ShimmerLine(width: 200, height: 22)
            ShimmerLine(width: 100, height: 12)
        }
        .padding(AppSpacing.md)
        .background(AppPalette.elevatedBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
    }
}
