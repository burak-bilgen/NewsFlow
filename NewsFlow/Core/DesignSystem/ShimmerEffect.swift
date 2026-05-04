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
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: Color(.systemBackground).opacity(0.3), location: 0.5),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .scaleEffect(x: 3)
                .offset(x: isAnimating ? containerWidth : -containerWidth)
                .animation(.easeInOut(duration: duration).repeatForever(autoreverses: false), value: isAnimating)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
            .onAppear { isAnimating = true }
    }

    private var containerWidth: CGFloat {
        UIScreen.main.bounds.width
    }
}

struct ShimmerLine: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: AppSpacing.xxs)
            .fill(Color(.tertiarySystemFill))
            .frame(width: width, height: height)
            .modifier(ShimmerEffect())
    }
}

struct SourceRowSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                ShimmerLine(width: 120, height: 18)
                Spacer(minLength: AppSpacing.sm)
                ShimmerLine(width: 60, height: 20)
            }
            ShimmerLine(width: .infinity, height: 14)
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

struct ArticleRowSkeleton: View {
    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            RoundedRectangle(cornerRadius: AppRadius.sm)
                .fill(Color(.tertiarySystemFill))
                .frame(width: 94, height: 86)
                .modifier(ShimmerEffect())

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                ShimmerLine(width: .infinity, height: 16)
                ShimmerLine(width: 200, height: 16)
                ShimmerLine(width: 80, height: 12)
                ShimmerLine(width: 140, height: 38)
            }
        }
        .padding(AppSpacing.md)
        .cardSurface()
    }
}

struct ArticleHeroSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(Color(.tertiarySystemFill))
                .frame(height: 170)
                .modifier(ShimmerEffect())

            ShimmerLine(width: .infinity, height: 20)
            ShimmerLine(width: 180, height: 20)
            ShimmerLine(width: 100, height: 12)
            ShimmerLine(width: 140, height: 38)
        }
        .padding(AppSpacing.md)
        .cardSurface()
    }
}

extension View {
    func shimmer(duration: Double = 1.5) -> some View {
        modifier(ShimmerEffect(duration: duration))
    }
}
