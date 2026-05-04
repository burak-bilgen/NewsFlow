import SwiftUI

// MARK: - Source Media Card

struct SourceMediaCard: View {
    let source: NewsSource
    var heroNamespace: Namespace.ID?

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            // Logo or fallback initials
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(Color(.tertiarySystemBackground))
                    .frame(width: 120, height: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                            .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                    )

                if let logoURL = source.logoURL {
                    AsyncImage(url: logoURL) { phase in
                        switch phase {
                        case let .success(image):
                            image
                                .resizable()
                                .scaledToFit()
                                .padding(AppSpacing.md)
                        case .failure, .empty:
                            fallbackInitials
                        @unknown default:
                            fallbackInitials
                        }
                    }
                    .frame(width: 120, height: 120)
                } else {
                    fallbackInitials
                }
            }
            .ifLet(heroNamespace) { view, ns in
                view.matchedGeometryEffect(id: "source.\(source.id)", in: ns)
            }

            Text(source.name)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(AppPalette.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 120)
        }
        .contentShape(Rectangle())
    }

    private var fallbackInitials: some View {
        Text(String(source.name.prefix(1)))
            .font(.system(size: 40, weight: .black, design: .serif))
            .foregroundColor(AppPalette.primaryRed)
            .frame(width: 120, height: 120)
    }
}
