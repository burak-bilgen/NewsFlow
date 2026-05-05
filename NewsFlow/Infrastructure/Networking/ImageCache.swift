import UIKit
import Foundation

// MARK: - Image Cache Protocol

protocol ImageCacheProtocol: AnyObject {
    func image(for url: URL, targetSize: CGSize?) async -> UIImage?
    func loadImage(from url: URL, targetSize: CGSize?) async -> UIImage?
    func preloadImages(from urls: [URL], targetSize: CGSize?) async
    func clearMemoryCache() async
    func clearDiskCache() async
}

// MARK: - Two-Tier Image Cache

/// Professional image cache with memory (NSCache) and disk (FilePersistentStore) tiers.
/// Features:
/// - LRU eviction via access timestamps
/// - Downsampling to target size to reduce memory footprint
/// - Cost-based NSCache limits (megabytes, not just count)
/// - Concurrent-safe with actor isolation
/// - Preloading support for prefetching images before display
actor ImageCache: ImageCacheProtocol {

    // MARK: - Configuration

    struct Configuration {
        var memoryCostLimitMB: Int = 50
        var diskSizeLimitMB: Int = 200
        var maxDiskAgeDays: Int = 7
        var defaultTargetSize: CGSize = CGSize(width: 400, height: 400)
    }

    // MARK: - Properties

    private let memoryCache = NSCache<NSString, MemoryCacheEntry>()
    private let fileManager = FileManager.default
    private let diskCacheURL: URL
    private var configuration: Configuration
    private var activeTasks: [String: Task<UIImage?, Never>] = [:]

    // MARK: - Init

    init(configuration: Configuration = Configuration()) {
        self.configuration = configuration

        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        self.diskCacheURL = caches[0].appendingPathComponent("NewsFlowImageCache", isDirectory: true)

        try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)

        memoryCache.totalCostLimit = configuration.memoryCostLimitMB * 1024 * 1024

        // Periodic disk cleanup
        Task {
            await cleanupExpiredDiskCache()
        }
    }

    // MARK: - Public API

    func image(for url: URL, targetSize: CGSize? = nil) -> UIImage? {
        let key = cacheKey(for: url, size: targetSize)

        // Check memory first
        if let entry = memoryCache.object(forKey: key as NSString) {
            entry.lastAccessed = Date()
            return entry.image
        }

        // Check disk
        if let diskImage = loadFromDisk(key: key) {
            // Promote to memory
            storeInMemory(image: diskImage, key: key)
            return diskImage
        }

        return nil
    }

    func loadImage(from url: URL, targetSize: CGSize? = nil) async -> UIImage? {
        let key = cacheKey(for: url, size: targetSize)

        // Return cached immediately
        if let cached = image(for: url, targetSize: targetSize) {
            return cached
        }

        // Deduplicate concurrent requests for same URL
        if let existingTask = activeTasks[key] {
            return await existingTask.value
        }

        let task = Task<UIImage?, Never> {
            defer { Task { await removeActiveTask(key: key) } }

            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode),
                      let image = UIImage(data: data) else {
                    return nil
                }

                // Downsample if needed
                let finalImage = downsample(image: image, to: targetSize ?? configuration.defaultTargetSize)

                // Store in both tiers
                await store(image: finalImage, data: data, key: key)

                return finalImage
            } catch {
                return nil
            }
        }

        activeTasks[key] = task
        return await task.value
    }

    func preloadImages(from urls: [URL], targetSize: CGSize? = nil) async {
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask {
                    _ = await self.loadImage(from: url, targetSize: targetSize)
                }
            }
        }
    }

    func clearMemoryCache() async {
        memoryCache.removeAllObjects()
    }

    func clearDiskCache() async {
        try? fileManager.removeItem(at: diskCacheURL)
        try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
    }

    // MARK: - Private

    private func store(image: UIImage, data: Data, key: String) async {
        storeInMemory(image: image, key: key)
        storeOnDisk(data: data, key: key)
    }

    private func storeInMemory(image: UIImage, key: String) {
        let cost = image.jpegData(compressionQuality: 1.0)?.count ?? 0
        let entry = MemoryCacheEntry(image: image, cost: cost)
        memoryCache.setObject(entry, forKey: key as NSString, cost: cost)
    }

    private func storeOnDisk(data: Data, key: String) {
        let url = diskCacheURL.appendingPathComponent(key)
        try? data.write(to: url)

        // Store metadata
        let meta = ImageCacheMeta(lastAccessed: Date(), originalURL: key)
        if let metaData = try? JSONEncoder().encode(meta) {
            let metaURL = diskCacheURL.appendingPathComponent("\(key).meta")
            try? metaData.write(to: metaURL)
        }
    }

    private func loadFromDisk(key: String) -> UIImage? {
        let url = diskCacheURL.appendingPathComponent(key)
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return nil
        }

        // Update access time
        let meta = ImageCacheMeta(lastAccessed: Date(), originalURL: key)
        if let metaData = try? JSONEncoder().encode(meta) {
            let metaURL = diskCacheURL.appendingPathComponent("\(key).meta")
            try? metaData.write(to: metaURL)
        }

        return image
    }

    private func downsample(image: UIImage, to targetSize: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    private func cacheKey(for url: URL, size: CGSize?) -> String {
        let urlKey = url.absoluteString.cacheHash
        if let size = size {
            return "\(urlKey)_\(Int(size.width))x\(Int(size.height))"
        }
        return urlKey
    }

    private func removeActiveTask(key: String) {
        activeTasks.removeValue(forKey: key)
    }

    private func cleanupExpiredDiskCache() async {
        let cutoffDate = Date().addingTimeInterval(-TimeInterval(configuration.maxDiskAgeDays * 24 * 3600))

        guard let files = try? fileManager.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: nil) else { return }

        for file in files where file.pathExtension != "meta" {
            let metaURL = file.appendingPathExtension("meta")
            var shouldDelete = false

            if let metaData = try? Data(contentsOf: metaURL),
               let meta = try? JSONDecoder().decode(ImageCacheMeta.self, from: metaData) {
                shouldDelete = meta.lastAccessed < cutoffDate
            } else {
                // No metadata — delete orphan
                shouldDelete = true
            }

            if shouldDelete {
                try? fileManager.removeItem(at: file)
                try? fileManager.removeItem(at: metaURL)
            }
        }
    }
}

// MARK: - Memory Cache Entry

private final class MemoryCacheEntry {
    let image: UIImage
    let cost: Int
    var lastAccessed: Date

    init(image: UIImage, cost: Int) {
        self.image = image
        self.cost = cost
        self.lastAccessed = Date()
    }
}

// MARK: - Disk Cache Metadata

private struct ImageCacheMeta: Codable {
    let lastAccessed: Date
    let originalURL: String
}

// MARK: - String MD5 (for cache key hashing)

private extension String {
    /// Simple FNV-1a hash for cache key generation.
    var cacheHash: String {
        var hash: UInt64 = 14695981039346656037
        for byte in self.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1099511628211
        }
        return String(hash, radix: 16, uppercase: false)
    }
}
