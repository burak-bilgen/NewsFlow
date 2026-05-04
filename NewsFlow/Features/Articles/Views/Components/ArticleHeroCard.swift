import SwiftUI

struct ArticleHeroCard: View {
    let article: Article
    let sourceName: String
    let isSaved: Bool
    var heroNamespace: Namespace.ID?
    var sourceID: String?
    let onToggle: () -> Void

    var body: some View {
        NavigationLink {
            ArticleDetailView(article: article, sourceName: sourceName)
        } label: {
            cardContent
        }
        .buttonStyle(.plain)
    }

    private var cardContent: some View {
        ZStack(alignment: .bottomLeading) {
            ArticleImageView(url: article.imageURL)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    .buttonStyle(.plain)
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

// Helper for optional matchedGeometryEffect with two values
extension View {
    @ViewBuilder
    func ifLet<T, U, Content: View>(_ value1: T?, _ value2: U?, transform: (Self, T, U) -> Content) -> some View {
        if let value1, let value2 {
            transform(self, value1, value2)
        } else {
            self
        }
    }
}

#if DEBUG
#Preview {
    ArticleHeroCard(
        article: NewsFixture.articlesBySource["bbc-news"]![0],
        sourceName: "BBC News",
        isSaved: false,
        onToggle: {}
    )
    .frame(height: 400)
    .padding()
}
#endif
