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
        case .loaded:
            articleList
        case .empty:
            StateMessageView(
                systemImage: "doc.text.magnifyingglass",
                title: L10n.text("articles.empty.title"),
                message: L10n.text("articles.empty.message"),
                retryTitle: L10n.text("retry.button")
            ) {
                Task { await viewModel.retry() }
            }
        case let .error(message):
            StateMessageView(
                systemImage: "exclamationmark.triangle",
                title: L10n.text("error.title"),
                message: message,
                retryTitle: L10n.text("retry.button")
            ) {
                Task { await viewModel.retry() }
            }
        }
    }

    private var articleList: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.md) {
                if !viewModel.featuredArticles.isEmpty {
                    FeaturedCarouselView(viewModel: viewModel)
                }

                ForEach(viewModel.listArticles) { article in
                    ArticleRowView(
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
        withAnimation(.easeInOut(duration: 0.25)) {
            viewModel.carouselSelection = (viewModel.carouselSelection + 1) % count
        }
    }
}

private struct ArticleRowView: View {
    let article: Article
    let isSaved: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            ArticleImageView(url: article.imageURL)
                .frame(width: 94, height: 86)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(article.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(3)

                Text(article.displayDate)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button(isSaved ? L10n.text("readingList.remove") : L10n.text("readingList.add")) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        onToggle()
                    }
                }
                .buttonStyle(ReadingListButtonStyle())
                .accessibilityIdentifier("readingList.toggle.\(article.id)")
            }
        }
        .padding(AppSpacing.md)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }
}

private struct ArticleImageView: View {
    let url: URL?

    var body: some View {
        if let url {
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

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [AppPalette.softBlue.opacity(0.14), Color(.tertiarySystemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "newspaper")
                .font(.title2)
                .foregroundColor(AppPalette.softBlue.opacity(0.74))
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
        .frame(height: 320)
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .accessibilityIdentifier("articles.carousel")
    }
}

private struct ArticleHeroCard: View {
    let article: Article
    let isSaved: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            ArticleImageView(url: article.imageURL)
                .frame(height: 170)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))

            Text(article.title)
                .font(.headline)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            Text(article.displayDate)
                .font(.caption)
                .foregroundColor(.secondary)

            Button(isSaved ? L10n.text("readingList.remove") : L10n.text("readingList.add")) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    onToggle()
                }
            }
            .buttonStyle(ReadingListButtonStyle())
            .accessibilityIdentifier("readingList.toggle.\(article.id)")
        }
        .padding(AppSpacing.md)
        .cardSurface()
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
