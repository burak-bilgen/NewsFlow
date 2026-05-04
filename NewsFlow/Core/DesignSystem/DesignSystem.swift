import SwiftUI

enum AppSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

enum AppRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
}

enum AppPalette {
    static let screenBackground = Color(.systemGroupedBackground)
    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let elevatedBackground = Color(.systemBackground)
    static let border = Color.primary.opacity(0.08)

    static let primaryRed = Color(red: 0.77, green: 0.12, blue: 0.23)
    static let primaryRedDark = Color(red: 0.55, green: 0.05, blue: 0.14)
    static let primaryRedLight = Color(red: 0.92, green: 0.28, blue: 0.38)

    static let goldAccent = Color(red: 0.85, green: 0.65, blue: 0.13)

    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textOnImage = Color.white

    static let gradientStart = Color.black.opacity(0.7)
    static let gradientEnd = Color.black.opacity(0.0)
}

enum Haptic {
    @MainActor static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @MainActor static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    @MainActor static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}

struct CardSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppPalette.elevatedBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

struct ReadingListButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)
            .background(
                configuration.isPressed
                    ? AppPalette.primaryRedDark
                    : AppPalette.primaryRed
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
    }
}

struct CategoryChipStyle: ViewModifier {
    let isSelected: Bool

    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)
            .foregroundColor(isSelected ? .white : AppPalette.primaryRed)
            .background(isSelected ? AppPalette.primaryRed : AppPalette.elevatedBackground)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : AppPalette.primaryRed.opacity(0.3), lineWidth: 1.5)
            )
    }
}

extension View {
    func cardSurface() -> some View {
        modifier(CardSurface())
    }

    func categoryChip(isSelected: Bool) -> some View {
        modifier(CategoryChipStyle(isSelected: isSelected))
    }
}
