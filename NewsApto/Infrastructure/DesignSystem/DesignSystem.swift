import SwiftUI

// MARK: - Color Palette (AMOLED True Black + #39FF14 Neon Green)

enum AppPalette {
    static let background = Color(red: 0, green: 0, blue: 0)
    static let surface = Color(red: 0.05, green: 0.05, blue: 0.05)
    static let surfaceElevated = Color(red: 0.08, green: 0.08, blue: 0.08)
    static let cardBorder = Color(red: 0.15, green: 0.15, blue: 0.15)
    static let borderLight = Color(red: 0.10, green: 0.10, blue: 0.10)
    static let dividerBorder = Color(red: 0.10, green: 0.10, blue: 0.10)
    static let warning = Color(red: 1.0, green: 0.68, blue: 0.18)

    static let textPrimary = Color(red: 0.96, green: 0.96, blue: 0.96)
    static let textSecondary = Color(red: 0.60, green: 0.60, blue: 0.60)
    static let textTertiary = Color(red: 0.40, green: 0.40, blue: 0.40)

    /// #39FF14 — True Neon Green
    static let accent = Color(red: 0.224, green: 1.0, blue: 0.078)
    static let accentDim = accent.opacity(0.12)
    static let accentMuted = accent.opacity(0.06)

    static let error = Color(red: 1.0, green: 0.27, blue: 0.27)
    static let success = accent
}

// MARK: - Typography

enum AppTypography {
    static let largeTitle = Font.system(size: 28, weight: .bold, design: .default)
    static let title = Font.system(size: 20, weight: .bold, design: .default)
    static let headline = Font.system(size: 17, weight: .semibold, design: .default)
    static let body = Font.system(size: 15, weight: .regular, design: .default)
    static let caption = Font.system(size: 12, weight: .medium, design: .default)
    static let small = Font.system(size: 10, weight: .medium, design: .default)
    static let monoSmall = Font.system(size: 10, weight: .regular, design: .monospaced)
    static let monoTiny = Font.system(size: 8, weight: .regular, design: .monospaced)

    // Extended tokens for specific screens
    static let splashTitle = Font.system(size: 32, weight: .black, design: .serif)
    static let splashSubtitle = Font.system(size: 14, weight: .regular, design: .serif)
    static let stateTitle = Font.system(size: 22, weight: .black, design: .serif)
}

// MARK: - Spacing (8pt Grid)

enum AppSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

// MARK: - Animation (Crisp Digital / Terminal Style)

enum AppAnimation {
    /// Fast, crisp press feedback — no bounce
    static let press = Animation.easeOut(duration: 0.10)
    /// Standard digital reveal
    static let reveal = Animation.easeOut(duration: 0.20)
    /// Content transition (category switch, filter change)
    static let transition = Animation.easeOut(duration: 0.25)
    /// Staggered list item appearance
    static func stagger(index: Int) -> Animation {
        .easeOut(duration: 0.22).delay(Double(index) * 0.04)
    }
    /// Slow ambient pulse (glow effects)
    static let pulse = Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)
    /// Terminal cursor blink
    static let blink = Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)
}

// MARK: - Minimum Tap Target (HIG: 44pt)

private let kMinTapTarget: CGFloat = 44

// MARK: - View Extensions

extension View {
    func cardStyle() -> some View {
        self.background(AppPalette.surface)
            .overlay(Rectangle().stroke(AppPalette.cardBorder, lineWidth: 0.5))
    }

    func pressable() -> some View {
        self.buttonStyle(DigitalButtonStyle())
    }
}

// MARK: - Digital Button Style (Crisp, No Bounce)

struct DigitalButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(AppAnimation.press, value: configuration.isPressed)
    }
}

// MARK: - Buttons (44pt Minimum Tap Targets)

struct NeonButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            action()
        } label: {
            Text(title)
                .font(AppTypography.caption.weight(.semibold))
                .foregroundColor(.black)
                .padding(.horizontal, 16)
                .frame(minHeight: kMinTapTarget)
                .background(AppPalette.accent)
        }
        .buttonStyle(.plain)
    }
}

struct OutlineButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Text(title)
                .font(AppTypography.caption.weight(.semibold))
                .foregroundColor(AppPalette.accent)
                .padding(.horizontal, 16)
                .frame(minHeight: kMinTapTarget)
                .overlay(Rectangle().stroke(AppPalette.accent.opacity(0.4), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shimmer

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = -1
    let duration: Double = 1.8
    func body(content: Content) -> some View {
        content.overlay(
            GeometryReader { _ in
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: phase - 0.3),
                        .init(color: AppPalette.accent.opacity(0.06), location: phase),
                        .init(color: .clear, location: phase + 0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ).scaleEffect(x: 2.5)
            }
        ).clipShape(RoundedRectangle(cornerRadius: 4)).onAppear {
            withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: false)) { phase = 1.5 }
        }
    }
}

struct ShimmerLine: View {
    let w: CGFloat; let h: CGFloat
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(AppPalette.surface)
            .frame(maxWidth: w, minHeight: h, maxHeight: h)
            .modifier(ShimmerEffect())
    }
}
