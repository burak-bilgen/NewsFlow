import SwiftUI

struct FeaturedCarouselView: View {
    @ObservedObject var viewModel: ArticlesViewModel
    var heroNamespace: Namespace.ID?
    var onManualInteraction: () -> Void = {}

    var body: some View {
        GeometryReader { geometry in
            TabView(selection: $viewModel.carouselSelection) {
                ForEach(Array(viewModel.featuredArticles.enumerated()), id: \.element.id) { index, article in
                    ArticleHeroCard(
                        article: article,
                        sourceName: viewModel.source.name,
                        heroNamespace: index == 0 ? heroNamespace : nil,
                        sourceID: viewModel.source.id
                    )
                    .padding(.horizontal, AppSpacing.md)
                    .tag(index)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .tabViewStyle(.page(indexDisplayMode: .always))
            .simultaneousGesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { _ in onManualInteraction() }
            )
        }
        .frame(height: 400)
        .clipped()
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
