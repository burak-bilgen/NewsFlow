import Foundation
import UIKit

actor ImageCache {
    struct Configuration {
        var memoryCostLimitMB: Int = 50
        var diskSizeLimitMB: Int = 200
        var maxDiskAgeDays: Int = 7
        var defaultTargetSize = CGSize(width: 400, height: 400)
    }

    private let memoryCache = NSCache<NSString, MemoryCacheEntry>()
    private let fileManager = FileManager.default
    private let diskCacheURL: URL
    private var configuration: Configuration
    private var activeTasks: [String: Task<UIImage?, Never>] = [:]

    init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        self.diskCacheURL = caches[0].appendingPathComponent("NewsAptoImageCache", isDirectory: true)
        try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        memoryCache.totalCostLimit = configuration.memoryCostLimitMB * 1024 * 1024
    }

    func loadImage(from url: URL, targetSize: CGSize? = nil) async -> UIImage? {
        let key = cacheKey(for: url, size: targetSize)

        if let cached = cachedImage(key: key) { return cached }

        if let existingTask = activeTasks[key] {
            return await existingTask.value
        }

        let task = Task<UIImage?, Never> {
            defer { removeActiveTask(key: key) }
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode),
                      let image = UIImage(data: data) else { return nil }

                let finalImage = downsample(image: image, to: targetSize ?? configuration.defaultTargetSize)
                store(image: finalImage, data: data, key: key)
                return finalImage
            } catch { return nil }
        }

        activeTasks[key] = task
        return await task.value
    }

    func preloadImages(from urls: [URL], targetSize: CGSize? = nil) async {
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask { _ = await self.loadImage(from: url, targetSize: targetSize) }
            }
        }
    }

    func clearMemoryCache() async { memoryCache.removeAllObjects() }

    func clearDiskCache() async {
        try? fileManager.removeItem(at: diskCacheURL)
        try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
    }

    // MARK: - Private

    private func cachedImage(key: String) -> UIImage? {
        if let entry = memoryCache.object(forKey: key as NSString) {
            entry.lastAccessed = Date(); return entry.image
        }
        if let diskImage = loadFromDisk(key: key) {
            storeInMemory(image: diskImage, key: key); return diskImage
        }
        return nil
    }

    private func store(image: UIImage, data: Data, key: String) {
        storeInMemory(image: image, key: key)
        storeOnDisk(data: data, key: key)
    }

    private func storeInMemory(image: UIImage, key: String) {
        let cost = image.jpegData(compressionQuality: 1.0)?.count ?? 0
        memoryCache.setObject(MemoryCacheEntry(image: image, cost: cost), forKey: key as NSString, cost: cost)
    }

    private func storeOnDisk(data: Data, key: String) {
        let url = diskCacheURL.appendingPathComponent(key)
        try? data.write(to: url)
        if let metaData = try? JSONEncoder().encode(ImageCacheMeta(lastAccessed: Date(), originalURL: key)) {
            try? metaData.write(to: diskCacheURL.appendingPathComponent("\(key).meta"))
        }
    }

    private func loadFromDisk(key: String) -> UIImage? {
        guard let data = try? Data(contentsOf: diskCacheURL.appendingPathComponent(key)),
              let image = UIImage(data: data) else { return nil }
        if let metaData = try? JSONEncoder().encode(ImageCacheMeta(lastAccessed: Date(), originalURL: key)) {
            try? metaData.write(to: diskCacheURL.appendingPathComponent("\(key).meta"))
        }
        return image
    }

    private func downsample(image: UIImage, to targetSize: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat(); format.scale = 1.0
        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    private func cacheKey(for url: URL, size: CGSize?) -> String {
        let urlKey = url.absoluteString.cacheHash
        if let size = size { return "\(urlKey)_\(Int(size.width))x\(Int(size.height))" }
        return urlKey
    }

    private func removeActiveTask(key: String) {
        activeTasks.removeValue(forKey: key)
    }
}

private final class MemoryCacheEntry {
    let image: UIImage; let cost: Int; var lastAccessed: Date
    init(image: UIImage, cost: Int) { self.image = image; self.cost = cost; self.lastAccessed = Date() }
}

private struct ImageCacheMeta: Codable {
    let lastAccessed: Date; let originalURL: String
}

private extension String {
    var cacheHash: String {
        var hash: UInt64 = 14695981039346656037
        for byte in self.utf8 { hash ^= UInt64(byte); hash &*= 1099511628211 }
        return String(hash, radix: 16, uppercase: false)
    }
}
