import SwiftUI

// MARK: - Smooth Matrix Emission Transition

struct MatrixEmissionTransition: ViewModifier {
    let trigger: AnyHashable
    @State private var contentOpacity: Double = 1
    @State private var glowOpacity: Double = 0
    @State private var verticalOffset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .opacity(contentOpacity)
            .offset(y: verticalOffset)
            .overlay(
                Rectangle()
                    .fill(AppPalette.accent)
                    .opacity(glowOpacity)
                    .allowsHitTesting(false)
            )
            .onChange(of: trigger) { _, _ in
                fadeCycle()
            }
    }

    private func fadeCycle() {
        contentOpacity = 0
        verticalOffset = 12
        glowOpacity = 0.08

        withAnimation(.easeOut(duration: 0.15)) {
            glowOpacity = 0
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.85).delay(0.08)) {
            contentOpacity = 1
            verticalOffset = 0
        }
    }
}

// MARK: - Glitch Reveal (initial load)

struct GlitchRevealModifier: ViewModifier {
    @State private var offsetX: CGFloat = 0
    @State private var opacity: Double = 0

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .offset(x: offsetX)
            .onAppear {
                let steps = 6
                for i in 0..<steps {
                    let delay = Double(i) * 0.03
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        withAnimation(.easeOut(duration: 0.02)) {
                            offsetX = CGFloat.random(in: -3...3)
                            opacity = min(1.0, Double(i + 1) / Double(steps))
                        }
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(steps) * 0.03) {
                    withAnimation(.easeOut(duration: 0.05)) { offsetX = 0; opacity = 1 }
                }
            }
    }
}

// MARK: - Glow Pulse (active category button)

struct GlowPulseModifier: ViewModifier {
    let isActive: Bool
    @State private var pulse = false

    func body(content: Content) -> some View {
        content
            .overlay(
                isActive ?
                    RoundedRectangle(cornerRadius: 0)
                    .stroke(AppPalette.accent.opacity(pulse ? 0.5 : 0.1), lineWidth: 2)
                    .padding(-2)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
                    .onAppear { pulse = true }
                : nil
            )
    }
}

// MARK: - View Extensions

extension View {
    func glitchReveal() -> some View { modifier(GlitchRevealModifier()) }
    func matrixEmission(trigger: AnyHashable) -> some View { modifier(MatrixEmissionTransition(trigger: trigger)) }
    func glowPulse(isActive: Bool) -> some View { modifier(GlowPulseModifier(isActive: isActive)) }
}
