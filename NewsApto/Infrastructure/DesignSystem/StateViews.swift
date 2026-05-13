import SwiftUI

// MARK: - StateMessageView (Empty / Error / Success states)

struct StateMessageView: View {
    let systemImage: String
    let title: String
    let message: String
    var retryTitle: String?
    var retryAction: (() -> Void)?

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            // Animated illustration with bounce
            ZStack {
                // Outer pulsing ring
                Circle()
                    .stroke(AppPalette.accent.opacity(0.15), lineWidth: 2)
                    .frame(width: isAnimating ? 120 : 100, height: isAnimating ? 120 : 100)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)

                // Middle ring
                Circle()
                    .fill(AppPalette.accent.opacity(0.08))
                    .frame(width: 90, height: 90)

                // Icon
                Image(systemName: systemImage)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(AppPalette.accent)
                    .symbolRenderingMode(.hierarchical)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
            }
            .frame(width: 120, height: 120)

            VStack(spacing: AppSpacing.sm) {
                Text(title)
                    .font(AppTypography.stateTitle)
                    .multilineTextAlignment(.center)
                    .foregroundColor(AppPalette.textPrimary)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(AppPalette.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, AppSpacing.xl)
            }

            if let retryTitle, let retryAction {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                        retryAction()
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .semibold))
                        Text(retryTitle)
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.md)
                    .background(
                        Rectangle()
                            .fill(AppPalette.accent)
                            .shadow(color: AppPalette.accent.opacity(0.3), radius: 12, x: 0, y: 6)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("state.retry.button")
                .scaleEffect(isAnimating ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppSpacing.xl)
        .onAppear { isAnimating = true }
    }
}

#if DEBUG
#if !CODEX_DISABLE_PREVIEWS
#Preview("Error State") {
    StateMessageView(
        systemImage: "exclamationmark.triangle.fill",
        title: "Something Went Wrong",
        message: "We couldn't load the articles. Please check your connection and try again.",
        retryTitle: "Try Again",
        retryAction: {}
    )
}

#Preview("Empty State") {
    StateMessageView(
        systemImage: "newspaper.fill",
        title: "No Articles Found",
        message: "There are no articles available from this source at the moment."
    )
}
#endif

#endif
