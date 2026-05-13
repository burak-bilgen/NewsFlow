import SwiftUI

struct FeedHeaderView: View {
    let onReadingListTap: () -> Void
    let onAttributionTap: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .accessibilityHidden(true)

            Spacer(minLength: 16)

            HStack(spacing: 10) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onReadingListTap()
                } label: {
                    HomeHeaderIcon(systemName: "bookmark", accessibilityLabel: "Reading list")
                }
                .buttonStyle(HomeHeaderButtonStyle())

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onAttributionTap()
                } label: {
                    HomeHeaderIcon(systemName: "info", accessibilityLabel: "About")
                }
                .buttonStyle(HomeHeaderButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 18)
    }
}

private struct HomeHeaderIcon: View {
    let systemName: String
    let accessibilityLabel: String

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(AppPalette.accent.opacity(0.32), lineWidth: 0.8)
                .frame(width: 40, height: 40)

            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(AppPalette.textPrimary)
        }
        .frame(width: 46, height: 46)
        .contentShape(Circle())
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct HomeHeaderButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .opacity(configuration.isPressed ? 0.72 : 1)
            .animation(AppAnimation.press, value: configuration.isPressed)
    }
}

#if DEBUG
#if !CODEX_DISABLE_PREVIEWS
#Preview {
    ZStack {
        AppPalette.background.ignoresSafeArea()
        FeedHeaderView(
            onReadingListTap: {},
            onAttributionTap: {}
        )
        .padding()
    }
}
#endif
#endif
