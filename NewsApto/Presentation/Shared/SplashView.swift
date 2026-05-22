import SwiftUI

struct SplashView: View {
    @State private var scale: CGFloat = 0.6
    @State private var opacity: CGFloat = 0
    @State private var textOpacity: CGFloat = 0
    @State private var taglineOpacity: CGFloat = 0
    @State private var isComplete = false

    let onComplete: () -> Void

    var body: some View {
        ZStack {
            AppPalette.background.ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer()

                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .scaleEffect(scale)
                    .opacity(opacity)

                Text(L10n.text("app.name"))
                    .font(AppTypography.splashTitle)
                    .foregroundColor(AppPalette.textPrimary)
                    .opacity(textOpacity)

                Text(L10n.text("splash.tagline"))
                    .font(AppTypography.splashSubtitle)
                    .foregroundColor(AppPalette.accent)
                    .opacity(taglineOpacity)

                Spacer()

                Text(L10n.text("splash.sources"))
                    .font(AppTypography.monoTiny)
                    .foregroundColor(AppPalette.textTertiary)
                    .opacity(taglineOpacity)
                    .padding(.bottom, 40)
            }
        }
        .statusBarHidden(true)
        .onAppear {
            withAnimation(AppAnimation.transition) {
                scale = 1.0
                opacity = 1.0
            }
            withAnimation(AppAnimation.reveal.delay(0.3)) {
                textOpacity = 1.0
            }
            withAnimation(AppAnimation.reveal.delay(0.5)) {
                taglineOpacity = 1.0
            }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.8))
                withAnimation(AppAnimation.press) {
                    isComplete = true
                }
                onComplete()
            }
        }
    }
}
