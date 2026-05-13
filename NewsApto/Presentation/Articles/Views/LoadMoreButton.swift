import SwiftUI

struct LoadMoreButton: View {
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack {
                Spacer()

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(AppPalette.accent)
                } else {
                    HStack(spacing: AppSpacing.sm) {
                        Text(L10n.text("articles.loadMore"))
                            .font(.subheadline.weight(.bold))

                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(AppPalette.accent)
                }

                Spacer()
            }
            .padding(.vertical, AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppPalette.surfaceElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(AppPalette.accent.opacity(0.3), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityIdentifier("articles.loadMore")
    }
}

#if DEBUG
#if !CODEX_DISABLE_PREVIEWS
#Preview {
    VStack(spacing: 20) {
        LoadMoreButton(isLoading: false) {}
        LoadMoreButton(isLoading: true) {}
    }
    .padding()
}
#endif

#endif
