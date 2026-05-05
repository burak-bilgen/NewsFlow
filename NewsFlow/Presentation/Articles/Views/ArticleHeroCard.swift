import SwiftUI

struct ArticleHeroCard: View {
    let article: Article
    let sourceName: String
    var heroNamespace: Namespace.ID?
    var sourceID: String?
    var isSaved: Bool = false
    var onToggle: (() -> Void)?
    @State private var isPressed = false

    var body: some View {
        NavigationLink {
            ArticleDetailView(
                article: article,
                sourceName: sourceName,
                isSaved: isSaved,
                onToggleReadingList: onToggle
            )
        } label: {
            ZStack(alignment: .topTrailing) {
                cardContent
                
                if let onToggle = onToggle {
                    ReadingListToggleButton(
                        isSaved: isSaved,
                        displayStyle: .hero,
                        action: onToggle
                    )
                    .padding(AppSpacing.md)
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }

    private var cardContent: some View {
        ZStack(alignment: .bottomLeading) {
            ArticleImageView(url: article.imageURL)
                .ifLet(heroNamespace, sourceID) { view, ns, id in
                    view.matchedGeometryEffect(id: "source.\(id)", in: ns)
                }

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
                    Spacer()
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
        .shadow(color: AppPalette.shadowColor, radius: 20, x: 0, y: 10)
    }
}

#if DEBUG
#Preview {
    ArticleHeroCard(
        article: NewsFixture.articlesBySource["bbc-news"]![0],
        sourceName: "BBC News",
        heroNamespace: nil,
        sourceID: nil
    )
    .frame(height: 400)
    .padding()
}
#endif
