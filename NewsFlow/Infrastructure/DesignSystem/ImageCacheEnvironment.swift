import SwiftUI
import UIKit

// MARK: - Legacy Image Cache Servicing Protocol

/// Protocol for image caching used in SwiftUI environment.
/// Kept for backward compatibility with existing views.
protocol ImageCacheServicing: AnyObject {
    func image(for url: URL) -> UIImage?
    func loadImage(from url: URL) async -> UIImage?
    func preloadImages(from urls: [URL], targetSize: CGSize?) async
    func clearMemory() async
}

// MARK: - Adapter

/// Adapter that bridges the new two-tier ImageCache actor to the legacy protocol.
final class ImageCacheAdapter: ImageCacheServicing {
    private let cache: ImageCache

    init(cache: ImageCache = ImageCache()) {
        self.cache = cache
    }

    func image(for url: URL) -> UIImage? {
        // Legacy sync API — cannot access actor-isolated state synchronously
        // Return nil; callers should use async loadImage instead
        nil
    }

    func loadImage(from url: URL) async -> UIImage? {
        await cache.loadImage(from: url, targetSize: nil)
    }

    func preloadImages(from urls: [URL], targetSize: CGSize?) async {
        await cache.preloadImages(from: urls, targetSize: targetSize)
    }

    func clearMemory() async {
        await cache.clearMemoryCache()
    }
}

// MARK: - ImageCache Environment Key

private struct ImageCacheKey: EnvironmentKey {
    static let defaultValue: ImageCacheServicing = ImageCacheAdapter()
}

extension EnvironmentValues {
    var imageCache: ImageCacheServicing {
        get { self[ImageCacheKey.self] }
        set { self[ImageCacheKey.self] = newValue }
    }
}
