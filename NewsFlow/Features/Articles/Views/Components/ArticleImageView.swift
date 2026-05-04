import SwiftUI

struct ArticleImageView: View {
    let url: URL?
    @Environment(\.imageCache) private var imageCache
    @State private var cachedImage: Image?
    @State private var loadTask: Task<Void, Never>?
    @State private var isLoaded = false

    var body: some View {
        ZStack {
            if let cachedImage {
                cachedImage
                    .resizable()
                    .scaledToFill()
                    .opacity(isLoaded ? 1 : 0)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            isLoaded = true
                        }
                    }
            } else if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                            .opacity(isLoaded ? 1 : 0)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 0.35)) {
                                    isLoaded = true
                                }
                            }
                    case .failure, .empty:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .clipped()
        .onAppear {
            guard let url, cachedImage == nil else { return }
            loadTask = Task {
                if let uiImage = await imageCache.loadImage(from: url) {
                    guard !Task.isCancelled else { return }
                    cachedImage = Image(uiImage: uiImage)
                }
            }
        }
        .onDisappear {
            loadTask?.cancel()
            loadTask = nil
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel(L10n.text("article.image.placeholder"))
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 20) {
        ArticleImageView(url: URL(string: "https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=400"))
            .frame(width: 200, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))

        ArticleImageView(url: nil)
            .frame(width: 200, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
#endif
