import SwiftUI

// MARK: - Source Media Card

/// Displays a news source with its logo (fetched from Clearbit) or a
/// fallback initials placeholder. The entire card has a fixed size so
/// rows never jitter when images finish loading.
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

/// Loads an image through the injected ImageCacheService and falls back
/// to a placeholder if the load fails or the URL is invalid.
private struct CachedAsyncImage: View {
    let url: URL
    @Environment(\.imageCache) private var imageCache
    @State private var uiImage: UIImage?
    @State private var didFail = false

    var body: some View {
        ZStack {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .padding(AppSpacing.sm)
            } else if didFail {
                placeholder
            } else {
                placeholder
                    .opacity(0.5)
            }
        }
        .task(id: url) {
            await load()
        }
    }

    private func load() async {
        didFail = false
        if let cached = imageCache.image(for: url) {
            uiImage = cached
            return
        }
        if let loaded = await imageCache.loadImage(from: url) {
            uiImage = loaded
        } else {
            didFail = true
        }
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                .fill(AppPalette.primaryRed.opacity(0.08))
            Image(systemName: "newspaper.fill")
                .font(.system(size: 24))
                .foregroundColor(AppPalette.primaryRed.opacity(0.3))
        }
    }
}
