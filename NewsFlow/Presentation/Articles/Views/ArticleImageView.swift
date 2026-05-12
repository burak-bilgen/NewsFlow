import SwiftUI

/// A safe image view that never expands beyond its container.
///
/// Design decisions:
/// - Uses GeometryReader to measure the *actual* container width and forces
///   the image to fill that exact space. This prevents the image's intrinsic
///   size from pushing parent views off-screen.
/// - `.clipped()` is applied *after* the frame so overflow is visually cut.
/// - Falls back to a placeholder when the URL is nil or loading fails.
struct ArticleImageView: View {
    let url: URL?
    @Environment(\.imageCache) private var imageCache
    @State private var uiImage: UIImage?
    @State private var didFail = false
    @State private var loadTask: Task<Void, Never>?
    @State private var isLoaded = false
    @State private var isLoading = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .opacity(isLoaded ? 1 : 0)
                        .onAppear {
                            withAnimation(.easeOut(duration: 0.3)) {
                                isLoaded = true
                            }
                        }
                } else if didFail || url == nil {
                    placeholder
                } else if isLoading {
                    loadingPlaceholder
                } else {
                    placeholder
                        .opacity(0.6)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
            .task(id: url) {
                await loadImage(into: geometry.size)
            }
        }
    }

    private func loadImage(into size: CGSize) async {
        guard let url else { return }
        didFail = false
        isLoading = true

        if let cached = imageCache.image(for: url) {
            uiImage = cached
            isLoading = false
            return
        }

        loadTask?.cancel()
        loadTask = Task {
            if let loaded = await imageCache.loadImage(from: url) {
                guard !Task.isCancelled else { return }
                isLoading = false
                uiImage = loaded
            } else {
                guard !Task.isCancelled else { return }
                isLoading = false
                didFail = true
            }
        }
    }

    private var loadingPlaceholder: some View {
        ZStack {
            Rectangle()
                .fill(Color(.systemGray5))
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, Color.white.opacity(0.4), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .modifier(ShimmerEffect())
                )
        }
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [AppPalette.primaryRed.opacity(0.12), Color(.tertiarySystemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "newspaper.fill")
                .font(.system(size: 32))
                .foregroundColor(AppPalette.primaryRed.opacity(0.35))
        }
        .accessibilityLabel(L10n.text("article.image.placeholder"))
    }
}

#if DEBUG
#if !CODEX_DISABLE_PREVIEWS
#Preview {
    VStack(spacing: 20) {
        ArticleImageView(url: URL(string: "https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=400"))
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))

        ArticleImageView(url: nil)
            .frame(width: 200, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .padding()
}
#endif

#endif
