import SwiftUI
import Combine

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
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
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
            LazyVStack(spacing: AppSpacing.md) {
                if !viewModel.featuredArticles.isEmpty {
                    FeaturedCarouselView(viewModel: viewModel)
                }

                if !viewModel.listArticles.isEmpty {
                    SectionHeaderView(title: L10n.text("articles.latest"))
                        .padding(.horizontal, AppSpacing.md)
                }

                ForEach(viewModel.listArticles) { article in
                    ArticleCardView(
                        article: article,
                        isSaved: viewModel.isSaved(article)
                    ) {
                        Task { await viewModel.toggleReadingList(for: article) }
                    }
                    .padding(.horizontal, AppSpacing.md)
                }
            }
            .padding(.vertical, AppSpacing.md)
        }
        .refreshable {
            await viewModel.pullToRefresh()
        }
        .accessibilityIdentifier("articles.list")
    }

    private func advanceCarousel() {
        let count = viewModel.featuredArticles.count
        guard count > 1 else { return }
        withAnimation(Accessibility.isReduceMotionEnabled ? nil : .easeInOut(duration: 0.25)) {
            viewModel.carouselSelection = (viewModel.carouselSelection + 1) % count
        }
    }
}

private struct SectionHeaderView: View {
    let title: String

    var body: some View {
        HStack {
            Rectangle()
                .fill(AppPalette.primaryRed)
                .frame(width: 4, height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            Text(title)
                .font(.title3.weight(.bold))
                .foregroundColor(AppPalette.textPrimary)

            Spacer()
        }
    }
}

private struct ArticleCardView: View {
    let article: Article
    let isSaved: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ArticleImageView(url: article.imageURL)
                .frame(height: 200)
                .clipShape(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                )

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(article.title)
                    .font(.headline.weight(.semibold))
                    .lineLimit(2)
                    .foregroundColor(AppPalette.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                HStack {
                    Text(article.displayDate)
                        .font(.caption.weight(.medium))
                        .foregroundColor(AppPalette.textSecondary)

                    Spacer()

                    Button(isSaved ? L10n.text("readingList.remove") : L10n.text("readingList.add")) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            onToggle()
                        }
                        Haptic.light()
                    }
                    .buttonStyle(ReadingListButtonStyle())
                }
            }
            .padding(AppSpacing.md)
        }
        .background(AppPalette.elevatedBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(article.title), \(article.displayDate)")
    }
}

private struct ArticleImageView: View {
    let url: URL?
    @State private var cachedImage: Image?
    @State private var loadTask: Task<Void, Never>?

    var body: some View {
        Group {
            if let cachedImage {
                cachedImage
                    .resizable()
                    .scaledToFill()
            } else if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
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
                colors: [AppPalette.primaryRed.opacity(0.15), Color(.tertiarySystemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "newspaper.fill")
                .font(.system(size: 48))
                .foregroundColor(AppPalette.primaryRed.opacity(0.4))
        }
        .accessibilityLabel(L10n.text("article.image.placeholder"))
    }
}

private struct FeaturedCarouselView: View {
    @ObservedObject var viewModel: ArticlesViewModel

    var body: some View {
        TabView(selection: $viewModel.carouselSelection) {
            ForEach(Array(viewModel.featuredArticles.enumerated()), id: \.element.id) { index, article in
                ArticleHeroCard(
                    article: article,
                    isSaved: viewModel.isSaved(article)
                ) {
                    Task { await viewModel.toggleReadingList(for: article) }
                }
                .padding(.horizontal, AppSpacing.md)
                .tag(index)
            }
        }
        .frame(height: 380)
        .tabViewStyle(.page(indexDisplayMode: .always))
        .accessibilityIdentifier("articles.carousel")
    }
}

private struct ArticleHeroCard: View {
    let article: Article
    let isSaved: Bool
    let onToggle: () -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ArticleImageView(url: article.imageURL)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            LinearGradient(
                colors: [Color.black.opacity(0.75), Color.black.opacity(0.2), Color.clear],
                startPoint: .bottom,
                endPoint: .top
            )

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            onToggle()
                        }
                        Haptic.light()
                    } label: {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(isSaved ? AppPalette.goldAccent : .white)
                            .shadow(color: .black.opacity(0.5), radius: 2)
                    }
                }

                Spacer()

                Text(article.title)
                    .font(.title3.weight(.bold))
                    .foregroundColor(.white)
                    .lineLimit(3)
                    .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 1)

                Text(article.displayDate)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white.opacity(0.85))
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            }
            .padding(AppSpacing.lg)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .shadow(color: Color.black.opacity(0.15), radius: 16, x: 0, y: 8)
    }
}

private struct ArticlesSkeletonView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.md) {
                ArticleHeroSkeleton()
                    .padding(.horizontal, AppSpacing.md)

                ForEach(0..<3, id: \.self) { _ in
                    ArticleRowSkeleton()
                        .padding(.horizontal, AppSpacing.md)
                }
            }
            .padding(.vertical, AppSpacing.md)
        }
    }
}
