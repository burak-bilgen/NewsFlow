import SwiftUI

struct ReadingListToggleButton: View {
    enum DisplayStyle {
        case card
        case hero

        var foregroundColor: Color {
            switch self {
            case .card:
                return AppPalette.primaryRed
            case .hero:
                return .white
            }
        }

        var savedForegroundColor: Color {
            switch self {
            case .card:
                return AppPalette.goldAccent
            case .hero:
                return AppPalette.goldAccent
            }
        }

        var background: Color {
            switch self {
            case .card:
                return AppPalette.primaryRedMuted
            case .hero:
                return Color.black.opacity(0.35)
            }
        }
    }

    let isSaved: Bool
    let displayStyle: DisplayStyle
    let action: () -> Void

    private var title: String {
        L10n.text(isSaved ? "readingList.remove" : "readingList.add")
    }

    private var iconName: String {
        isSaved ? "bookmark.fill" : "bookmark"
    }

    private var foregroundColor: Color {
        isSaved ? displayStyle.savedForegroundColor : displayStyle.foregroundColor
    }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                action()
            }
            Haptic.light()
        } label: {
            Label {
                Text(title)
                    .font(.caption.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            } icon: {
                Image(systemName: iconName)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(foregroundColor)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(
                Capsule()
                    .fill(displayStyle.background)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityIdentifier("article.bookmark")
    }
}
