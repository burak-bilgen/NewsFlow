import SwiftUI

// MARK: - Dynamic Colors

/// Dynamic color provider that adapts to light/dark mode.
private func dynamicColor(light: UIColor, dark: UIColor) -> Color {
    Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? dark : light
    })
}

// MARK: - Spacing

enum AppSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

// MARK: - Radius

enum AppRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
}

// MARK: - Palette

enum AppPalette {
    // Backgrounds
    static let screenBackground = dynamicColor(
        light: UIColor(red: 0.97, green: 0.95, blue: 0.92, alpha: 1),
        dark: UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 1)
    )

    static let cardBackground = dynamicColor(
        light: UIColor(red: 0.94, green: 0.92, blue: 0.89, alpha: 1),
        dark: UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1)
    )

    static let elevatedBackground = dynamicColor(
        light: UIColor(red: 1.0, green: 0.98, blue: 0.96, alpha: 1),
        dark: UIColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 1)
    )

    static let border = Color.primary.opacity(0.15)

    // Text (use SwiftUI .primary/.secondary for auto adaptation)
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textOnImage = Color.white

    // Accents
    static let primaryInk = dynamicColor(
        light: UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1),
        dark: UIColor(red: 0.92, green: 0.92, blue: 0.92, alpha: 1)
    )

    static let primaryInkDark = dynamicColor(
        light: UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 1),
        dark: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
    )

    static let primaryInkLight = dynamicColor(
        light: UIColor(red: 0.28, green: 0.28, blue: 0.28, alpha: 1),
        dark: UIColor(red: 0.72, green: 0.72, blue: 0.72, alpha: 1)
    )

    static let primaryInkMuted = dynamicColor(
        light: UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 0.08),
        dark: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.08)
    )

    // Legacy aliases
    static let primaryRed = accentRed
    static let primaryRedDark = accentRedDark
    static let primaryRedLight = accentRedLight
    static let primaryRedMuted = accentRedMuted

    // Accent Colors (true red - consistent across themes)
    static let accentRed = Color(red: 0.85, green: 0.22, blue: 0.21)
    static let accentRedDark = Color(red: 0.95, green: 0.45, blue: 0.44)
    static let accentRedLight = Color(red: 0.75, green: 0.12, blue: 0.11)
    static let accentRedMuted = Color(red: 0.85, green: 0.22, blue: 0.21).opacity(0.15)

    static let goldAccent = Color(red: 0.85, green: 0.65, blue: 0.13)

    // Gradients
    static let gradientStart = Color.black.opacity(0.85)
    static let gradientMid = Color.black.opacity(0.45)
    static let gradientEnd = Color.black.opacity(0.0)

    // Shadows
    static let shadowColor = dynamicColor(
        light: UIColor.black.withAlphaComponent(0.18),
        dark: UIColor.black.withAlphaComponent(0.50)
    )
}

// MARK: - Haptic

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

// MARK: - View Modifiers

struct CardSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppPalette.elevatedBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .shadow(color: AppPalette.shadowColor, radius: 14, x: 0, y: 6)
    }
}

struct ElevatedCardSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppPalette.elevatedBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
            .shadow(color: AppPalette.shadowColor, radius: 20, x: 0, y: 10)
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
            .foregroundColor(isSelected ? .white : AppPalette.primaryRed)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)
            .background(
                Capsule()
                    .fill(isSelected ? AppPalette.primaryRed : AppPalette.elevatedBackground)
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? Color.clear : AppPalette.primaryRed.opacity(0.3), lineWidth: 1.5)
                    )
            )
    }
}

extension View {
    func cardSurface() -> some View {
        modifier(CardSurface())
    }

    func elevatedCardSurface() -> some View {
        modifier(ElevatedCardSurface())
    }

    func categoryChip(isSelected: Bool) -> some View {
        modifier(CategoryChipStyle(isSelected: isSelected))
    }
}
