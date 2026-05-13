import SwiftUI

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

    static let accent = Color(red: 0.22, green: 1.0, blue: 0.08)
    static let accentDim = Color(red: 0.22, green: 1.0, blue: 0.08).opacity(0.12)
    static let accentMuted = Color(red: 0.22, green: 1.0, blue: 0.08).opacity(0.06)

    static let error = Color(red: 1.0, green: 0.27, blue: 0.27)
    static let success = Color(red: 0.22, green: 1.0, blue: 0.08)
}

enum AppTypography {
    static let largeTitle = Font.system(size: 28, weight: .bold, design: .default)
    static let title = Font.system(size: 20, weight: .bold, design: .default)
    static let headline = Font.system(size: 17, weight: .semibold, design: .default)
    static let body = Font.system(size: 15, weight: .regular, design: .default)
    static let caption = Font.system(size: 12, weight: .medium, design: .default)
    static let small = Font.system(size: 10, weight: .medium, design: .default)
    static let monoSmall = Font.system(size: 10, weight: .regular, design: .monospaced)
    static let monoTiny = Font.system(size: 8, weight: .regular, design: .monospaced)
}

enum AppSpacing {
    static let xxs: CGFloat = 4; static let xs: CGFloat = 8
    static let sm: CGFloat = 12; static let md: CGFloat = 16
    static let lg: CGFloat = 20; static let xl: CGFloat = 24; static let xxl: CGFloat = 32
}

extension View {
    func cardStyle() -> some View {
        self.background(AppPalette.surface).overlay(RoundedRectangle(cornerRadius: 0).stroke(AppPalette.cardBorder, lineWidth: 0.5))
    }
    func pressable() -> some View { self.buttonStyle(SpringButtonStyle()) }
}

struct SpringButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct NeonButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.caption.weight(.semibold))
                .foregroundColor(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(AppPalette.accent)
        }
        .buttonStyle(.plain)
    }
}

struct OutlineButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.caption.weight(.semibold))
                .foregroundColor(AppPalette.accent)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .overlay(RoundedRectangle(cornerRadius: 0).stroke(AppPalette.accent.opacity(0.4), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }
}

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = -1
    let duration: Double = 1.8
    func body(content: Content) -> some View {
        content.overlay(
            GeometryReader { g in
                LinearGradient(stops: [.init(color: .clear, location: phase - 0.3), .init(color: AppPalette.accent.opacity(0.06), location: phase), .init(color: .clear, location: phase + 0.3)], startPoint: .topLeading, endPoint: .bottomTrailing).scaleEffect(x: 2.5)
            }
        ).clipShape(RoundedRectangle(cornerRadius: 4)).onAppear {
            withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: false)) { phase = 1.5 }
        }
    }
}

struct ShimmerLine: View {
    let w: CGFloat; let h: CGFloat
    var body: some View {
        RoundedRectangle(cornerRadius: 4).fill(AppPalette.surface).frame(maxWidth: w, minHeight: h, maxHeight: h).modifier(ShimmerEffect())
    }
}

func springAnimation() -> Animation {
    .spring(response: 0.35, dampingFraction: 0.75)
}
