import SwiftUI

enum AppSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
}

enum AppRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
}

enum AppPalette {
    static let screenBackground = Color(.systemGroupedBackground)
    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let elevatedBackground = Color(.systemBackground)
    static let border = Color.primary.opacity(0.08)
    static let softBlue = Color(red: 0.08, green: 0.23, blue: 0.46)
    static let actionBlue = Color(red: 0.02, green: 0.31, blue: 0.72)
}

struct CardSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppPalette.elevatedBackground)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .stroke(AppPalette.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
    }
}

struct ReadingListButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.footnote.weight(.semibold))
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.85)
            .foregroundColor(.white)
            .padding(.horizontal, AppSpacing.md)
            .frame(minHeight: 38)
            .background(AppPalette.actionBlue.opacity(configuration.isPressed ? 0.82 : 1))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
    }
}

extension View {
    func cardSurface() -> some View {
        modifier(CardSurface())
    }
}
