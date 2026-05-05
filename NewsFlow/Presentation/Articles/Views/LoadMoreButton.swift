import SwiftUI

struct LoadMoreButton: View {
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Spacer()

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(AppPalette.primaryRed)
                } else {
                    HStack(spacing: AppSpacing.sm) {
                        Text(L10n.text("articles.loadMore"))
                            .font(.subheadline.weight(.bold))

                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(AppPalette.primaryRed)
                }

                Spacer()
            }
            .padding(.vertical, AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .fill(AppPalette.elevatedBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                            .stroke(AppPalette.primaryRed.opacity(0.3), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityIdentifier("articles.loadMore")
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 20) {
        LoadMoreButton(isLoading: false) {}
        LoadMoreButton(isLoading: true) {}
    }
    .padding()
}
#endif
