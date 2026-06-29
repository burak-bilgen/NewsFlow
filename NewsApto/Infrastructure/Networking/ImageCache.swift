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
    private let screenScale: CGFloat = 3.0
    private var configuration: Configuration
    private var activeTasks: [String: Task<UIImage?, Never>] = [:]

    init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        self.diskCacheURL = cacheDir.appendingPathComponent("NewsAptoImageCache", isDirectory: true)
        try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        memoryCache.totalCostLimit = configuration.memoryCostLimitMB * 1024 * 1024
        Task { await cleanDiskCache() }
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
                      (200...299).contains(httpResponse.statusCode) else { return nil }

                let finalImage = downsample(data: data, to: targetSize ?? configuration.defaultTargetSize)
                if let image = finalImage {
                    store(image: image, data: data, key: key)
                }
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

    func cleanDiskCache() async {
        let resourceKeys: Set<URLResourceKey> = [.contentModificationDateKey, .fileSizeKey]
        guard let allFiles = try? fileManager.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: Array(resourceKeys)) else { return }

        var files: [(url: URL, modDate: Date, size: Int)] = []
        var totalSize = 0

        for file in allFiles {
            guard file.pathExtension != "meta" else { continue }
            guard let resources = try? file.resourceValues(forKeys: resourceKeys),
                  let modDate = resources.contentModificationDate,
                  let fileSize = resources.fileSize else { continue }
            files.append((file, modDate, fileSize))
            totalSize += fileSize
        }

        let maxAge: TimeInterval = TimeInterval(configuration.maxDiskAgeDays * 86400)
        let maxSize = configuration.diskSizeLimitMB * 1024 * 1024
        let now = Date()

        for file in files where now.timeIntervalSince(file.modDate) > maxAge {
            try? fileManager.removeItem(at: file.url)
            try? fileManager.removeItem(at: file.url.appendingPathExtension("meta"))
            totalSize -= file.size
        }

        if totalSize > maxSize {
            let sorted = files
                .filter { now.timeIntervalSince($0.modDate) <= maxAge }
                .sorted { $0.modDate < $1.modDate }
            for file in sorted {
                try? fileManager.removeItem(at: file.url)
                try? fileManager.removeItem(at: file.url.appendingPathExtension("meta"))
                totalSize -= file.size
                if totalSize <= maxSize { break }
            }
        }
    }


    private func cachedImage(key: String) -> UIImage? {
        if let entry = memoryCache.object(forKey: key as NSString) {
            updateLastAccessed(entry)
            return entry.image
        }
        if let diskImage = loadFromDisk(key: key) {
            storeInMemory(image: diskImage, key: key); return diskImage
        }
        return nil
    }

    private nonisolated func updateLastAccessed(_ entry: MemoryCacheEntry) {
        entry.lastAccessed = Date()
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

    func downsample(data: Data, to targetSize: CGSize) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }

        let maxDimension = max(targetSize.width, targetSize.height) * screenScale
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return UIImage(data: data)
        }

        return UIImage(cgImage: cgImage)
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
