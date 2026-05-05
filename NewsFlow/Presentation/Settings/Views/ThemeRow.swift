import SwiftUI

struct ThemeRow: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                themeIcon
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                            .fill(isSelected ? AppPalette.primaryRed.opacity(0.12) : Color(.tertiarySystemFill))
                    )

                Text(theme.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppPalette.primaryRed)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("theme.row.\(theme.rawValue)")
    }

    @ViewBuilder
    private var themeIcon: some View {
        switch theme {
        case .light:
            Image(systemName: "sun.max.fill")
                .foregroundColor(.orange)

        case .dark:
            Image(systemName: "moon.fill")
                .foregroundColor(.indigo)

        case .system:
            Image(systemName: "circle.lefthalf.filled")
                .foregroundColor(.gray)
        }
    }
}
