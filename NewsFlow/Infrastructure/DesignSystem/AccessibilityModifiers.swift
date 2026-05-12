import SwiftUI

extension View {
    func accessibilityArticle(_ article: Article, isSaved: Bool) -> some View {
        let hint: String
        if isSaved {
            hint = L10n.text("article.accessibility.read", L10n.text("article.accessibility.saved"))
        } else {
            hint = L10n.text("article.accessibility.read", L10n.text("article.accessibility.save_hint"))
        }
        return self
            .accessibilityLabel(article.title)
            .accessibilityHint(hint)
            .accessibilityAddTraits(.isButton)
    }

    func accessibilityCarousel(index: Int, total: Int) -> some View {
        self
            .accessibilityLabel(L10n.text("feed.accessibility.featured", index + 1, total))
            .accessibilityHint(L10n.text("feed.accessibility.featured.hint"))
    }

    func accessibilitySourceCard(_ source: NewsSource) -> some View {
        self
            .accessibilityLabel(source.name)
            .accessibilityHint(L10n.text("feed.accessibility.source.hint"))
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
