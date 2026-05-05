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
                return AppPalette.elevatedBackground
            case .hero:
                return Color.black.opacity(0.35)
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .card:
                return 14
            case .hero:
                return 13
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
            Image(systemName: iconName)
                .font(.system(size: displayStyle.iconSize, weight: .semibold))
                .frame(width: 18, height: 18)
            .foregroundColor(foregroundColor)
            .padding(displayStyle == .hero ? 10 : 9)
            .background(
                Circle()
                    .fill(displayStyle.background)
            )
            .overlay(
                Circle()
                    .stroke(AppPalette.border, lineWidth: displayStyle == .card ? 1 : 0)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityIdentifier("article.bookmark")
    }
}
