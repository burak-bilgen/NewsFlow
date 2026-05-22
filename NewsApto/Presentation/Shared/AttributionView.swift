import SwiftUI

struct AttributionView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                apiCreditsSection
                disclaimerSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .background(AppPalette.background)
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppPalette.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(AppPalette.surface)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(.top, 12)
            .padding(.trailing, 16)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 10) {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 58, height: 58)
                .accessibilityHidden(true)

            Text("NewsApto")
                .font(AppTypography.largeTitle)
                .foregroundColor(AppPalette.textPrimary)

            Text(L10n.text("attribution.subtitle"))
                .font(AppTypography.body)
                .foregroundColor(AppPalette.textSecondary)

            Text(versionDisplay)
                .font(AppTypography.monoSmall)
                .foregroundColor(AppPalette.accent)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    private var apiCreditsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle(L10n.text("attribution.data_sources"))

            VStack(spacing: 0) {
                // Tier 1: Original Sources
                APITerminalRow(
                    name: "NewsAPI.org",
                    description: L10n.text("attribution.newsapi.desc"),
                    urlString: "https://newsapi.org"
                )
                Divider().overlay(AppPalette.dividerBorder).padding(.leading, 20)
                APITerminalRow(
                    name: "The Guardian",
                    description: L10n.text("attribution.guardian.desc"),
                    urlString: "https://www.theguardian.com"
                )
                Divider().overlay(AppPalette.dividerBorder).padding(.leading, 20)
                APITerminalRow(
                    name: "The New York Times",
                    description: L10n.text("attribution.nyt.desc"),
                    urlString: "https://www.nytimes.com"
                )
                
                Divider().overlay(AppPalette.dividerBorder).padding(.leading, 20)
                APITerminalRow(
                    name: "GNews",
                    description: L10n.text("attribution.gnews.desc"),
                    urlString: "https://gnews.io"
                )
                Divider().overlay(AppPalette.dividerBorder).padding(.leading, 20)
                APITerminalRow(
                    name: "NewsData.io",
                    description: L10n.text("attribution.newsdata.desc"),
                    urlString: "https://newsdata.io"
                )
                Divider().overlay(AppPalette.dividerBorder).padding(.leading, 20)
                APITerminalRow(
                    name: "HackerNews",
                    description: L10n.text("attribution.hn.desc"),
                    urlString: "https://news.ycombinator.com"
                )
            }
            .background(AppPalette.surface)
            .overlay(Rectangle().stroke(AppPalette.cardBorder, lineWidth: 0.5))
        }
    }

    private var disclaimerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(L10n.text("attribution.disclosure.section"))
            Text(L10n.text("attribution.disclosure.text"))
                .font(AppTypography.caption)
                .foregroundColor(AppPalette.textSecondary.opacity(0.82))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(AppTypography.small.weight(.bold))
            .foregroundColor(AppPalette.accent)
            .padding(.bottom, 12)
    }

    private var versionDisplay: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return String(format: L10n.text("attribution.version"), version, build)
    }
}

private struct APITerminalRow: View {
    let name: String
    let description: String
    let urlString: String

    var body: some View {
        if let url = URL(string: urlString) {
            Link(destination: url) {
                rowContent
            }.buttonStyle(.plain)
        } else {
            rowContent
        }
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            Text(">")
                .font(AppTypography.monoSmall)
                .foregroundColor(AppPalette.accent)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 5) {
                Text(name)
                    .font(AppTypography.caption.weight(.bold))
                    .foregroundColor(AppPalette.textPrimary)

                Text(description)
                    .font(AppTypography.small)
                    .foregroundColor(AppPalette.textSecondary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                Text(L10n.text("attribution.visit_source"))
                    .font(AppTypography.monoSmall)
                    .foregroundColor(AppPalette.accent)
            }

            Spacer(minLength: 12)

            Image(systemName: "arrow.up.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AppPalette.accent)
        }
        .padding(14)
        .contentShape(Rectangle())
    }
}
