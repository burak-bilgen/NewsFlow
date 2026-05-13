import SwiftUI

struct ArticleBadgeView: View {
    let badges: [Article.ArticleBadge]
    let size: BadgeSize
    
    enum BadgeSize {
        case small, medium, large
        
        var font: Font {
            switch self {
            case .small: return AppTypography.monoTiny
            case .medium: return AppTypography.monoSmall
            case .large: return AppTypography.caption
            }
        }
        
        var padding: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 6
            case .large: return 8
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(badges.prefix(3), id: \.self) { badge in
                badgeView(for: badge)
            }
        }
    }
    
    private func badgeView(for badge: Article.ArticleBadge) -> some View {
        let config = badgeConfig(for: badge)
        
        return Text(badge.rawValue)
            .font(size.font)
            .foregroundColor(config.foreground)
            .padding(.horizontal, size.padding)
            .padding(.vertical, size.padding / 2)
            .background(config.background)
            .overlay(
                Rectangle()
                    .stroke(config.border, lineWidth: 0.5)
            )
    }
    
    private func badgeConfig(for badge: Article.ArticleBadge) -> BadgeConfig {
        switch badge {
        case .breaking:
            return BadgeConfig(
                foreground: .black,
                background: AppPalette.accent,
                border: AppPalette.accent
            )
        case .trending:
            return BadgeConfig(
                foreground: Color(red: 1.0, green: 0.3, blue: 0.3),
                background: Color(red: 1.0, green: 0.3, blue: 0.3).opacity(0.15),
                border: Color(red: 1.0, green: 0.3, blue: 0.3).opacity(0.5)
            )
        case .editorsChoice:
            return BadgeConfig(
                foreground: Color(red: 1.0, green: 0.8, blue: 0.0),
                background: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.15),
                border: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.5)
            )
        case .personalized:
            return BadgeConfig(
                foreground: Color(red: 0.3, green: 0.6, blue: 1.0),
                background: Color(red: 0.3, green: 0.6, blue: 1.0).opacity(0.15),
                border: Color(red: 0.3, green: 0.6, blue: 1.0).opacity(0.5)
            )
        case .multiSource:
            return BadgeConfig(
                foreground: Color(red: 0.8, green: 0.3, blue: 1.0),
                background: Color(red: 0.8, green: 0.3, blue: 1.0).opacity(0.15),
                border: Color(red: 0.8, green: 0.3, blue: 1.0).opacity(0.5)
            )
        case .highQuality:
            return BadgeConfig(
                foreground: AppPalette.accent,
                background: AppPalette.accent.opacity(0.1),
                border: AppPalette.accent.opacity(0.3)
            )
        }
    }
    
    struct BadgeConfig {
        let foreground: Color
        let background: Color
        let border: Color
    }
}

struct CurationReasonView: View {
    let reason: Article.CurationReason?
    
    var body: some View {
        if let reason = reason {
            VStack(alignment: .leading, spacing: 4) {
                Text("> WHY THIS ARTICLE?")
                    .font(AppTypography.monoTiny)
                    .foregroundColor(AppPalette.textTertiary)
                
                HStack(spacing: 4) {
                    ForEach(reason.factors, id: \.self) { factor in
                        Text(factor)
                            .font(AppTypography.monoTiny)
                            .foregroundColor(AppPalette.accent)
                    }
                }
            }
            .padding(.top, 4)
        }
    }
}

#if DEBUG
#if !CODEX_DISABLE_PREVIEWS
#Preview {
    VStack(spacing: 16) {
        ArticleBadgeView(
            badges: [.breaking, .trending, .editorsChoice],
            size: .medium
        )
        
        ArticleBadgeView(
            badges: [.personalized, .highQuality],
            size: .small
        )
        
        CurationReasonView(reason: Article.CurationReason(
            reason: "Popular in tech",
            factors: ["🔥 Trending", "⭐ High Quality"]
        ))
    }
    .padding()
    .background(AppPalette.background)
}
#endif
#endif
