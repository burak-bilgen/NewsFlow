import SwiftUI

private func dynamicColor(light: UIColor, dark: UIColor) -> Color {
    Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? dark : light
    })
}

// MARK: - Typography

enum AppTypography {
    case heroTitle
    case sectionTitle
    case articleTitle
    case articleHeadline
    case body
    case caption
    case badge

    var font: Font {
        switch self {
        case .heroTitle:    return .system(size: 28, weight: .bold, design: .default)
        case .sectionTitle: return .system(size: 13, weight: .semibold, design: .default).uppercaseSmallCaps()
        case .articleTitle: return .system(size: 17, weight: .bold, design: .default)
        case .articleHeadline: return .system(size: 15, weight: .semibold, design: .default)
        case .body:         return .system(size: 13, weight: .regular, design: .default)
        case .caption:      return .system(size: 11, weight: .medium, design: .default)
        case .badge:        return .system(size: 9, weight: .bold, design: .default).uppercaseSmallCaps()
        }
    }
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
    static let xxxl: CGFloat = 40
}

// MARK: - Radius

enum AppRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
}

// MARK: - Modern Palette

enum AppPalette {
    // Backgrounds
    static let screenBackground = dynamicColor(
        light: UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1),
        dark: UIColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 1)
    )

    static let cardBackground = dynamicColor(
        light: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1),
        dark: UIColor(red: 0.10, green: 0.10, blue: 0.13, alpha: 1)
    )

    static let elevatedBackground = dynamicColor(
        light: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1),
        dark: UIColor(red: 0.14, green: 0.14, blue: 0.18, alpha: 1)
    )

    static let border = Color.primary.opacity(0.08)

    // Text
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color.secondary.opacity(0.6)
    static let textOnImage = Color.white

    // Brand — deep blue + coral accent
    static let brandPrimary = Color(red: 0.12, green: 0.30, blue: 0.75)
    static let brandPrimaryDark = Color(red: 0.08, green: 0.20, blue: 0.55)
    static let brandPrimaryLight = Color(red: 0.20, green: 0.40, blue: 0.85)
    static let brandPrimaryMuted = Color(red: 0.12, green: 0.30, blue: 0.75).opacity(0.12)

    static let accent = Color(red: 1.0, green: 0.40, blue: 0.30)
    static let accentDark = Color(red: 0.90, green: 0.30, blue: 0.20)
    static let accentMuted = Color(red: 1.0, green: 0.40, blue: 0.30).opacity(0.12)

    static let success = Color(red: 0.25, green: 0.78, blue: 0.45)
    static let warning = Color(red: 1.0, green: 0.68, blue: 0.18)
    static let error = Color(red: 0.92, green: 0.28, blue: 0.25)
    static let goldAccent = Color(red: 0.85, green: 0.65, blue: 0.13)

    // Legacy aliases
    static let primaryRed = accent
    static let primaryRedDark = accentDark
    static let primaryRedMuted = accentMuted

    // Gradients
    static let gradientDark = Color.black.opacity(0.80)
    static let gradientMid = Color.black.opacity(0.40)
    static let gradientClear = Color.black.opacity(0.0)

    static let brandGradient = LinearGradient(
        colors: [brandPrimary, brandPrimaryLight],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let accentGradient = LinearGradient(
        colors: [accent, Color(red: 1.0, green: 0.55, blue: 0.20)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    // Shadows
    static let shadowColor = dynamicColor(
        light: UIColor.black.withAlphaComponent(0.08),
        dark: UIColor.black.withAlphaComponent(0.35)
    )

    static let shadowColorStrong = dynamicColor(
        light: UIColor.black.withAlphaComponent(0.15),
        dark: UIColor.black.withAlphaComponent(0.50)
    )

    static let tabBarBackground = dynamicColor(
        light: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.85),
        dark: UIColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 0.85)
    )
}

// MARK: - Haptic

enum Haptic {
    @MainActor static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @MainActor static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    @MainActor static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    @MainActor static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    @MainActor static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

// MARK: - View Modifiers

struct CardSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppPalette.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
            .shadow(color: AppPalette.shadowColor, radius: 8, x: 0, y: 2)
    }
}

struct ElevatedCardSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppPalette.elevatedBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
            .shadow(color: AppPalette.shadowColorStrong, radius: 16, x: 0, y: 6)
    }
}

struct ModernButtonStyle: ButtonStyle {
    var color: Color = AppPalette.brandPrimary
    var isFullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.sm)
            .background(LinearGradient(colors: [color], startPoint: .leading, endPoint: .trailing))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct BadgeStyle: ViewModifier {
    var color: Color = AppPalette.brandPrimary

    func body(content: Content) -> some View {
        content
            .font(AppTypography.badge.font)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

struct CallToActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(configuration.isPressed ? AppPalette.accent.opacity(0.7) : AppPalette.accent)
            .contentShape(Rectangle())
    }
}

extension View {
    func cardSurface() -> some View { modifier(CardSurface()) }
    func elevatedCardSurface() -> some View { modifier(ElevatedCardSurface()) }
    func badgeStyle(color: Color = AppPalette.brandPrimary) -> some View { modifier(BadgeStyle(color: color)) }
}
