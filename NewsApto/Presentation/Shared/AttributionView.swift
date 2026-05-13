import SwiftUI

struct AttributionView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                apiCreditsSection
                disclaimerSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 28)
        }
        .background(AppPalette.background)
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

            Text("Independent news reader")
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
            sectionTitle("DATA SOURCES")

            VStack(spacing: 0) {
                APITerminalRow(
                    name: "NewsAPI.org",
                    description: "Top headlines from worldwide publishers. This product uses NewsAPI but is not endorsed or certified by NewsAPI.",
                    urlString: "https://newsapi.org"
                )
                Divider().overlay(AppPalette.dividerBorder).padding(.leading, 20)
                APITerminalRow(
                    name: "The Guardian",
                    description: "Global reporting across news, politics, culture, and more. Data provided by The Guardian Open Platform.",
                    urlString: "https://www.theguardian.com"
                )
                Divider().overlay(AppPalette.dividerBorder).padding(.leading, 20)
                APITerminalRow(
                    name: "The New York Times",
                    description: "Reporting and analysis from The New York Times Article Search API.",
                    urlString: "https://www.nytimes.com"
                )
            }
            .background(AppPalette.surface)
            .overlay(Rectangle().stroke(AppPalette.cardBorder, lineWidth: 0.5))
        }
    }

    private var disclaimerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("DISCLOSURE")
            Text("NewsApto is an independent news aggregator and is not affiliated with the listed publishers. Article content belongs to the original publishers and is provided by third-party APIs under their own terms.")
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
        return "> VERSION \(version) (\(build))"
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

                Text("> VISIT SOURCE")
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
