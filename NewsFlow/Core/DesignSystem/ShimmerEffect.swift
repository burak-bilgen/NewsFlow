import SwiftUI

struct ShimmerEffect: ViewModifier {
    @State private var isAnimating = false
    let duration: Double

    init(duration: Double = 1.5) {
        self.duration = duration
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: AppPalette.primaryRed.opacity(0.08), location: 0.5),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .scaleEffect(x: 3)
                    .offset(x: isAnimating ? geometry.size.width : -geometry.size.width)
                    .animation(.easeInOut(duration: duration).repeatForever(autoreverses: false), value: isAnimating)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
            .onAppear { isAnimating = true }
    }
}

struct ShimmerLine: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: AppSpacing.xxs)
            .fill(Color(.tertiarySystemFill))
            .frame(maxWidth: width, minHeight: height, maxHeight: height)
            .modifier(ShimmerEffect())
    }
}

extension View {
    func shimmer(duration: Double = 1.5) -> some View {
        modifier(ShimmerEffect(duration: duration))
    }
}
