import SwiftUI

struct ArticlesView: View {
    @StateObject private var viewModel: ArticlesViewModel

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
            await viewModel.load()
        }
        .accessibilityIdentifier("articles.screen")
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            LoadingStateView(text: L10n.text("articles.loading"))
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
                    ArticleRowView(article: article)
                        .padding(.horizontal, AppSpacing.md)
                }
            }
            .padding(.vertical, AppSpacing.md)
        }
        .accessibilityIdentifier("articles.list")
    }
}

private struct ArticleRowView: View {
    let article: Article

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
                ArticleHeroCard(article: article)
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
        }
        .padding(AppSpacing.md)
        .cardSurface()
    }
}
