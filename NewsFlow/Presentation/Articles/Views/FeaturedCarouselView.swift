import SwiftUI

struct FeaturedCarouselView: View {
    @ObservedObject var viewModel: ArticlesViewModel
    var heroNamespace: Namespace.ID?
    var onManualInteraction: () -> Void = {}

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                TabView(selection: $viewModel.carouselSelection) {
                    ForEach(Array(viewModel.featuredArticles.enumerated()), id: \.element.id) { index, article in
                        ArticleHeroCard(
                            article: article,
                            sourceName: viewModel.source.name,
                            heroNamespace: index == 0 ? heroNamespace : nil,
                            sourceID: viewModel.source.id,
                            isSaved: viewModel.isSaved(article),
                            onToggle: { Task { await viewModel.toggleReadingList(for: article) } }
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
                .onAppear {
                    viewModel.prefetchImages(for: viewModel.featuredArticles)
                }
                
                VStack {
                    HStack {
                        pageIndicator
                            .padding(.leading, AppSpacing.xxl)
                            .padding(.top, AppSpacing.md)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .frame(height: 400)
        .clipped()
        .accessibilityIdentifier("articles.carousel")
    }

    private var pageIndicator: some View {
        let current = viewModel.carouselSelection + 1
        let total = viewModel.featuredArticles.count
        return Text("\(current)/\(total)")
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.5))
            )
    }
}

#if DEBUG
#if !CODEX_DISABLE_PREVIEWS
#Preview {
    let vm = NewsFixture.previewViewModel()
    FeaturedCarouselView(viewModel: vm)
        .padding()
}
#endif

#endif
