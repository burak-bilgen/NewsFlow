import SwiftUI
import UIKit


protocol ImageCacheServicing: AnyObject {
    func loadImage(from url: URL) async -> UIImage?
    func preloadImages(from urls: [URL], targetSize: CGSize?) async
    func clearMemory() async
}


final class ImageCacheAdapter: ImageCacheServicing {
    private static let sharedCache = ImageCache()

    private let cache: ImageCache

    init(cache: ImageCache = ImageCacheAdapter.sharedCache) {
        self.cache = cache
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

    func clearAll() async {
        await cache.clearDiskCache()
        await cache.clearMemoryCache()
    }

    static func clearShared() async {
        let adapter = ImageCacheAdapter()
        await adapter.clearAll()
    }
}


private struct ImageCacheKey: EnvironmentKey {
    static let defaultValue: ImageCacheServicing = ImageCacheAdapter()
}

extension EnvironmentValues {
    var imageCache: ImageCacheServicing {
        get { self[ImageCacheKey.self] }
        set { self[ImageCacheKey.self] = newValue }
    }
}
