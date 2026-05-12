import SwiftUI

struct OnboardingView: View {
    @State private var appears = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    private let features: [FeatureItem] = [
        FeatureItem(
            icon: "newspaper.fill",
            title: L10n.text("onboarding.ai.title"),
            description: L10n.text("onboarding.ai.description"),
            color: AppPalette.brandPrimary
        ),
        FeatureItem(
            icon: "sparkle.magnifyingglass",
            title: L10n.text("onboarding.summary.title"),
            description: L10n.text("onboarding.summary.description"),
            color: AppPalette.accent
        ),
        FeatureItem(
            icon: "ear.fill",
            title: L10n.text("onboarding.tts.title"),
            description: L10n.text("onboarding.tts.description"),
            color: AppPalette.success
        ),
        FeatureItem(
            icon: "bookmark.fill",
            title: L10n.text("onboarding.bookmark.title"),
            description: L10n.text("onboarding.bookmark.description"),
            color: AppPalette.brandPrimaryLight
        ),
        FeatureItem(
            icon: "square.grid.2x2",
            title: L10n.text("onboarding.sources.title"),
            description: L10n.text("onboarding.sources.description"),
            color: AppPalette.accent
        )
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            AppPalette.screenBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroSection
                        .padding(.top, 60)
                        .padding(.bottom, 32)

                    featuresList
                        .padding(.bottom, 100)
                }
            }

            bottomButton
        }
        .onAppear { appears = true }
    }

    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppPalette.brandPrimary.opacity(0.08))
                    .frame(width: 100, height: 100)
                    .blur(radius: 16)
                Circle()
                    .fill(AppPalette.brandPrimary.opacity(0.15))
                    .frame(width: 72, height: 72)
                Image(systemName: "newspaper.fill")
                    .font(.system(size: 32))
                    .foregroundColor(AppPalette.brandPrimary)
                    .symbolRenderingMode(.hierarchical)
            }
            .scaleEffect(appears ? 1 : 0.5)
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: appears)

            VStack(spacing: 8) {
                Text("NewsFlow")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(AppPalette.textPrimary)

                Text(L10n.text("settings.appSubtitle"))
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(AppPalette.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .opacity(appears ? 1 : 0)
        .offset(y: appears ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.1), value: appears)
    }

    private var featuresList: some View {
        VStack(spacing: 12) {
            ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                FeatureCard(feature: feature, index: index, appears: appears)
            }
        }
        .padding(.horizontal, 20)
    }

    private var bottomButton: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [AppPalette.screenBackground.opacity(0), AppPalette.screenBackground],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 20)

            Button {
                Haptic.success()
                withAnimation { hasSeenOnboarding = true }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                    Text(L10n.text("onboarding.get_started"))
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(AppPalette.brandPrimary)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                .shadow(color: AppPalette.brandPrimary.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)

            Button {
                withAnimation { hasSeenOnboarding = true }
            } label: {
                Text(L10n.text("onboarding.skip"))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppPalette.textTertiary)
            }
            .padding(.bottom, 12)
        }
    }
}

// MARK: - Feature Card

private struct FeatureItem {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

private struct FeatureCard: View {
    let feature: FeatureItem
    let index: Int
    let appears: Bool
    @State private var isShowing = false

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(feature.color.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: feature.icon)
                    .font(.system(size: 20))
                    .foregroundColor(feature.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppPalette.textPrimary)

                Text(feature.description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(AppPalette.textSecondary)
                    .lineSpacing(2)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)
        }
        .padding(16)
        .background(AppPalette.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .shadow(color: AppPalette.shadowColor, radius: 4, x: 0, y: 1)
        .opacity(isShowing ? 1 : 0)
        .offset(x: isShowing ? 0 : -20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.08 + 0.15), value: isShowing)
        .onChange(of: appears) { newValue in
            if newValue { isShowing = true }
        }
    }
}

#if DEBUG
#Preview {
    OnboardingView()
}
#endif
