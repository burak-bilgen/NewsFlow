import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            AppPalette.background.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()

                Image("logo").resizable().scaledToFit().frame(width: 80, height: 80)

                Text(L10n.text("app.name"))
                    .font(AppTypography.splashTitle).foregroundColor(AppPalette.textPrimary)
                    .padding(.top, 12)

                Text(L10n.text("splash.tagline"))
                    .font(AppTypography.monoSmall).foregroundColor(AppPalette.accent)
                    .padding(.top, 4)

                Text(L10n.text("onboarding.welcome.message"))
                    .font(AppTypography.body).foregroundColor(AppPalette.textSecondary)
                    .multilineTextAlignment(.center).padding(.horizontal, 40)
                    .padding(.top, 20)

                VStack(spacing: 10) {
                    featureRow(icon: "newspaper", title: L10n.text("onboarding.feature.sources.title"), description: L10n.text("onboarding.feature.sources"))
                    featureRow(icon: "brain.head.profile", title: L10n.text("onboarding.feature.scoring"), description: L10n.text("onboarding.feature.scoring.desc"))
                    featureRow(icon: "magnifyingglass", title: L10n.text("onboarding.feature.search"), description: L10n.text("onboarding.feature.search.desc"))
                    featureRow(icon: "bookmark", title: L10n.text("readinglist.title"), description: L10n.text("onboarding.feature.readinglist"))
                }
                .padding(.horizontal, 32).padding(.top, 24)

                Spacer()

                Button {
                    onComplete()
                } label: {
                    Text(L10n.text("onboarding.get_started"))
                        .font(AppTypography.monoSmall).foregroundColor(.black)
                        .frame(maxWidth: .infinity).frame(height: 50).background(AppPalette.accent)
                        .padding(.horizontal, 32)
                }
                .buttonStyle(.plain).padding(.bottom, 50)
            }
        }
        .statusBarHidden(true)
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 20)).foregroundColor(AppPalette.accent).frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(AppTypography.monoSmall).foregroundColor(AppPalette.textPrimary)
                Text(description).font(AppTypography.caption).foregroundColor(AppPalette.textSecondary)
            }
            Spacer()
        }
        .padding(12).background(AppPalette.surface).overlay(Rectangle().stroke(AppPalette.accent.opacity(0.3), lineWidth: 0.5))
    }
}
