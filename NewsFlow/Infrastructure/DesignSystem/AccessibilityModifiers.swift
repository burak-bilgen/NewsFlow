import SwiftUI

extension View {
    func accessibilityArticle(_ article: Article, isSaved: Bool) -> some View {
        self
            .accessibilityLabel(article.title)
            .accessibilityHint("Double tap to read. \(isSaved ? "Saved." : "Tap bookmark to save.")")
            .accessibilityAddTraits(.isButton)
    }

    func accessibilityCarousel(index: Int, total: Int) -> some View {
        self
            .accessibilityLabel("Featured story \(index + 1) of \(total)")
            .accessibilityHint("Swipe to browse featured stories")
    }

    func accessibilitySourceCard(_ source: NewsSource) -> some View {
        self
            .accessibilityLabel("\(source.name)")
            .accessibilityHint("Tap to browse articles from this source")
            .accessibilityAddTraits(.isButton)
    }
}

struct ReduceMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let animation: Animation?

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.animation(animation, value: UUID())
        }
    }
}

extension View {
    func animatedUnlessReducedMotion(_ animation: Animation? = .spring(response: 0.4, dampingFraction: 0.8)) -> some View {
        modifier(ReduceMotionModifier(animation: animation))
    }
}
