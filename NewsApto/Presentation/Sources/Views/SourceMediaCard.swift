import SwiftUI

// MARK: - Source Media Card

/// Displays a news source with its logo (fetched from Clearbit) or a
/// fallback initials placeholder. The entire card has a fixed size so
/// rows never jitter when images finish loading.
struct SourceMediaCard: View {
    let source: NewsSource
    @State private var isPressed = false

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            logoContainer
                .frame(width: 100, height: 100)

            Text(source.name)
                .font(.system(size: 12, weight: .bold, design: .serif))
                .foregroundColor(AppPalette.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 100, height: 34, alignment: .top)
        }
        .frame(width: 108, height: 148)
        .contentShape(Rectangle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }

    private var logoContainer: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(.tertiarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )

            if let logoURL = source.logoURL {
                ArticleImageView(url: logoURL)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                fallbackInitials
            }
        }

    }

    private var fallbackInitials: some View {
        Text(source.nameInitials)
            .font(.system(size: 32, weight: .black, design: .serif))
            .foregroundColor(AppPalette.accent)
            .frame(width: 80, height: 80)
    }
}
