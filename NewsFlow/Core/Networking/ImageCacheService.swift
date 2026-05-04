import UIKit

final class ImageCacheService {
    static let shared = ImageCacheService()

    private let cache = NSCache<NSString, CacheEntry>()
    private let session: URLSession

    init(session: URLSession = .shared) {
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
            let (data, response) = try await session.data(from: url)
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

private final class CacheEntry {
    let image: UIImage
    init(image: UIImage) { self.image = image }
}
