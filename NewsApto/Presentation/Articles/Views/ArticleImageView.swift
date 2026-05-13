import SwiftUI

struct ArticleImageView: View {
    let url: URL?
    @Environment(\.imageCache) private var imageCache
    @State private var uiImage: UIImage?
    @State private var didFail = false
    @State private var isLoading = false

    var body: some View {
        ZStack {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .clipped()
            } else if didFail || url == nil {
                placeholder
            } else if isLoading {
                loadingPlaceholder
            } else {
                placeholder
            }
        }
        .clipped()
        .task(id: url) { await loadImage() }
    }

    private func loadImage() async {
        guard let url else { return }
        didFail = false; isLoading = true
        if let loaded = await imageCache.loadImage(from: url) {
            isLoading = false; uiImage = loaded
        } else {
            isLoading = false; didFail = true
        }
    }

    private var loadingPlaceholder: some View {
        Rectangle().fill(Color(.systemGray5))
            .overlay(Rectangle().fill(
                LinearGradient(colors: [.clear, Color.white.opacity(0.4), .clear], startPoint: .leading, endPoint: .trailing)
            ).modifier(ShimmerEffect()))
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(colors: [AppPalette.accent.opacity(0.12), Color(.tertiarySystemBackground)], startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: "newspaper.fill").font(.system(size: 28)).foregroundColor(AppPalette.accent.opacity(0.3))
        }
    }
}
