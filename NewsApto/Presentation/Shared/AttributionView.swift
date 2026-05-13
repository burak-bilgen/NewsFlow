import SwiftUI

struct AttributionView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                headerSection
                apiCreditsSection
                disclaimerSection
            }
            .padding(.horizontal, 24).padding(.vertical, 32)
        }
        .background(AppPalette.background)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("NewsApto")
                .font(AppTypography.largeTitle).foregroundColor(AppPalette.textPrimary)
            Text("> SYSTEM: OPERATIONAL").font(AppTypography.monoSmall).foregroundColor(AppPalette.accent)
        }
    }

    private var apiCreditsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("DATA SOURCES").font(AppTypography.small.weight(.bold)).foregroundColor(AppPalette.accent).padding(.bottom, 16)

            VStack(spacing: 0) {
                APITerminalRow(name: "NewsAPI.org", description: "Top headlines and breaking news from hundreds of sources worldwide. This product uses the NewsAPI but is not endorsed or certified by NewsAPI.") { UIApplication.shared.open(URL(string: "https://newsapi.org")!) }
                Divider().overlay(AppPalette.dividerBorder).padding(.leading, 20)
                APITerminalRow(name: "The Guardian", description: "Award-winning journalism covering global news, politics, culture and more. Data provided by The Guardian Open Platform.") { UIApplication.shared.open(URL(string: "https://www.theguardian.com")!) }
                Divider().overlay(AppPalette.dividerBorder).padding(.leading, 20)
                APITerminalRow(name: "The New York Times", description: "In-depth reporting and analysis from one of the world's leading newspapers. Data provided by The New York Times Article Search API.") { UIApplication.shared.open(URL(string: "https://www.nytimes.com")!) }
            }
            .background(AppPalette.surface)
            .overlay(Rectangle().stroke(AppPalette.cardBorder, lineWidth: 0.5))
        }
    }

    private var disclaimerSection: some View {
        VStack(spacing: 8) {
            Text("DISCLAIMER").font(AppTypography.small.weight(.bold)).foregroundColor(AppPalette.accent)
            Text("NewsApto is an independent news aggregator and is not affiliated with any listed source. All content is provided by third-party APIs and subject to their terms of service.").font(AppTypography.caption).foregroundColor(AppPalette.textSecondary.opacity(0.7)).lineSpacing(4).multilineTextAlignment(.center)
        }
    }
}

private struct APITerminalRow: View {
    let name: String; let description: String; let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(">").font(AppTypography.monoSmall).foregroundColor(AppPalette.accent).frame(width: 16)

                VStack(alignment: .leading, spacing: 4) {
                    Text(name).font(AppTypography.caption.weight(.bold)).foregroundColor(AppPalette.textPrimary)
                    Text(description).font(AppTypography.small).foregroundColor(AppPalette.textSecondary).lineLimit(nil).fixedSize(horizontal: false, vertical: true)
                    Text("> TAP TO VISIT").font(AppTypography.monoSmall).foregroundColor(AppPalette.accent)
                }
                Spacer()
            }
            .padding(14).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
