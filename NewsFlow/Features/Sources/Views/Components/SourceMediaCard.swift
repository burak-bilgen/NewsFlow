import SwiftUI

// MARK: - Source Media Card

struct SourceMediaCard: View {
    let source: NewsSource
    var heroNamespace: Namespace.ID?

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            logoContainer
                .frame(width: 100, height: 100)

            Text(source.name)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AppPalette.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 100, height: 34, alignment: .top)
        }
        .frame(width: 108, height: 148)
        .contentShape(Rectangle())
    }

    private var logoContainer: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(Color(.tertiarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )

            if let logoURL = source.logoURL {
                CachedAsyncImage(url: logoURL)
                    .frame(width: 80, height: 80)
            } else {
                fallbackInitials
            }
        }
        .ifLet(heroNamespace) { view, ns in
            view.matchedGeometryEffect(id: "source.\(source.id)", in: ns)
        }
    }

    private var fallbackInitials: some View {
        Text(source.nameInitials)
            .font(.system(size: 32, weight: .black, design: .serif))
            .foregroundColor(AppPalette.primaryRed)
            .frame(width: 80, height: 80)
    }
}

// MARK: - Cached Async Image

private struct CachedAsyncImage: View {
    let url: URL
    @Environment(\.imageCache) private var imageCache
    @State private var uiImage: UIImage?

    var body: some View {
        ZStack {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .padding(AppSpacing.sm)
            } else {
                ProgressView()
                    .scaleEffect(0.7)
                    .tint(AppPalette.primaryRed.opacity(0.5))
            }
        }
        .task {
            if let cached = imageCache.image(for: url) {
                uiImage = cached
            } else {
                uiImage = await imageCache.loadImage(from: url)
            }
        }
    }
}
