import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            AppPalette.background.ignoresSafeArea()
            VStack {
                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    featuresPage.tag(1)
                    permissionsPage.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                Button {
                    withAnimation { if currentPage < 2 { currentPage += 1 } else { onComplete() } }
                } label: {
                Text(currentPage < 2 ? L10n.text("onboarding.next") : L10n.text("onboarding.get_started"))
                    .font(AppTypography.monoSmall).foregroundColor(.black)
                        .frame(maxWidth: .infinity).frame(height: 50).background(AppPalette.accent)
                        .padding(.horizontal, 32)
                }
                .buttonStyle(.plain).padding(.bottom, 50)
            }
        }
        .statusBarHidden(true)
    }

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()
            Image("logo").resizable().scaledToFit().frame(width: 100, height: 100)
            Text(L10n.text("app.name")).font(AppTypography.splashTitle).foregroundColor(AppPalette.textPrimary)
            Text(L10n.text("splash.tagline")).font(AppTypography.monoSmall).foregroundColor(AppPalette.accent)
            Text(L10n.text("onboarding.welcome.message"))
                .font(AppTypography.body).foregroundColor(AppPalette.textSecondary).multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    private var featuresPage: some View {
        VStack(spacing: 20) {
            Spacer()
            Text(L10n.text("onboarding.features.title"))
                .font(AppTypography.title).foregroundColor(AppPalette.textPrimary).padding(.bottom, 8)
            featureRow(icon: "newspaper", title: L10n.text("onboarding.feature.sources.title"), description: L10n.text("onboarding.feature.sources"))
            featureRow(icon: "brain.head.profile", title: L10n.text("onboarding.feature.scoring"), description: L10n.text("onboarding.feature.scoring.desc"))
            featureRow(icon: "magnifyingglass", title: L10n.text("onboarding.feature.search"), description: L10n.text("onboarding.feature.search.desc"))
            featureRow(icon: "bookmark", title: L10n.text("readinglist.title"), description: L10n.text("onboarding.feature.readinglist"))
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var permissionsPage: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "bell.badge").font(.system(size: 60)).foregroundColor(AppPalette.accent)
            Text(L10n.text("onboarding.notifications.title"))
                .font(AppTypography.title).foregroundColor(AppPalette.textPrimary)
            Text(L10n.text("onboarding.notifications.message"))
                .font(AppTypography.body).foregroundColor(AppPalette.textSecondary).multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon).font(.system(size: 22)).foregroundColor(AppPalette.accent).frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(AppTypography.monoSmall).foregroundColor(AppPalette.textPrimary)
                Text(description).font(AppTypography.caption).foregroundColor(AppPalette.textSecondary)
            }
            Spacer()
        }
        .padding(12).background(AppPalette.surface).overlay(Rectangle().stroke(AppPalette.accent.opacity(0.3), lineWidth: 0.5))
    }
}
