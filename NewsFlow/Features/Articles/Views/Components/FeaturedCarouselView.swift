import SwiftUI

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

#if DEBUG
#Preview {
    let vm = NewsFixture.previewViewModel()
    FeaturedCarouselView(viewModel: vm)
        .padding()
}
#endif
