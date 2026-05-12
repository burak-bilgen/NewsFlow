import SwiftUI

struct FeedCarouselView: View {
    let articles: [Article]
    let isSaved: (Article) -> Bool
    let onToggleSave: (Article) -> Void
    @Binding var carouselSelection: Int
    var onManualInteraction: () -> Void = {}
    var heroNamespace: Namespace.ID?

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                TabView(selection: $carouselSelection) {
                    ForEach(Array(articles.enumerated()), id: \.element.id) { index, article in
                        ArticleHeroCard(
                            article: article,
                            sourceName: article.sourceName,
                            heroNamespace: index == 0 ? heroNamespace : nil,
                            sourceID: article.sourceID,
                            isSaved: isSaved(article),
                            onToggle: { onToggleSave(article) }
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
        .accessibilityIdentifier("feed.carousel")
    }

    private var pageIndicator: some View {
        let current = carouselSelection + 1
        let total = articles.count
        return Text("\(current)/\(total)")
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.black.opacity(0.5)))
    }
}
