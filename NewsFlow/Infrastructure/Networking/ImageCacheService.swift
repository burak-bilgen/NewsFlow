import Combine
import SwiftUI
import UIKit

// MARK: - ImageCacheService Protocol

/// Abstracts image caching for testability and dependency injection.
/// The production implementation uses NSCache for memory caching
/// with automatic eviction under memory pressure.
protocol ImageCacheServicing: AnyObject {
    func image(for url: URL) -> UIImage?
    func loadImage(from url: URL) async -> UIImage?
}

// MARK: - ImageCacheService Implementation

/// Production image cache backed by NSCache.
///
/// Design decisions:
/// - Not a singleton: injected via AppContainer so tests can swap in mocks.
/// - NSCache instead of dictionary: automatically evicts under memory pressure.
/// - countLimit = 100: prevents unbounded growth with high-res news images.
final class ImageCacheService: ImageCacheServicing {
    private let cache = NSCache<NSString, CacheEntry>()
    private let session: URLSessionProtocol

    init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
        cache.countLimit = 100
    }

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url.absoluteString as NSString)?.image
    }

    func loadImage(from url: URL) async -> UIImage? {
        if let cached = image(for: url) {
            return cached
        }

        do {
            let request = URLRequest(url: url)
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return nil
            }
            let image = UIImage(data: data)
            if let image {
                cache.setObject(CacheEntry(image: image), forKey: url.absoluteString as NSString)
            }
            return image
        } catch {
            return nil
        }
    }
}

// MARK: - Cache Entry

private final class CacheEntry {
    let image: UIImage
    init(image: UIImage) { self.image = image }
}
