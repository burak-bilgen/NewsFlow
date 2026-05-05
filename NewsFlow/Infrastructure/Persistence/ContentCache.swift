import Foundation

// MARK: - File Info (for cache eviction)

private struct FileInfo {
    let url: URL
    let size: Int64
    let date: Date
}

// MARK: - Content Cache Entry

struct CacheEntry<T: Codable>: Codable {
    let data: T
    let cachedAt: Date
    let ttlSeconds: TimeInterval

    var isExpired: Bool {
        Date().timeIntervalSince(cachedAt) > ttlSeconds
    }
}

// MARK: - Professional Content Cache

/// Generic content cache with TTL, LRU eviction, and disk persistence.
/// Supports any Codable type: Articles, Sources, Settings, etc.
actor ContentCache<T: Codable> {

    struct Configuration {
        var defaultTTL: TimeInterval = 300 // 5 minutes
        var maxDiskSizeMB: Int = 50
        var namespace: String
    }

    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let configuration: Configuration
    private var memoryCache: [String: CacheEntry<T>] = [:]
    private let maxMemoryEntries = 100

    init(configuration: Configuration) {
        self.configuration = configuration
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        self.cacheDirectory = caches[0]
            .appendingPathComponent("NewsFlowContentCache", isDirectory: true)
            .appendingPathComponent(configuration.namespace, isDirectory: true)

        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // Periodic cleanup
        Task {
            await clearExpired()
        }
    }

    // MARK: - Public API

    func get(forKey key: String) async -> T? {
        // Check memory first
        if let entry = memoryCache[key], !entry.isExpired {
            // Update LRU — move to end
            memoryCache.removeValue(forKey: key)
            memoryCache[key] = entry
            return entry.data
        }

        // Check disk
        if let entry = loadFromDisk(key: key) {
            if entry.isExpired {
                await remove(forKey: key)
                return nil
            }
            // Promote to memory
            storeInMemory(entry: entry, key: key)
            return entry.data
        }

        return nil
    }

    func set(_ value: T, forKey key: String, ttl: TimeInterval? = nil) async {
        let entry = CacheEntry(
            data: value,
            cachedAt: Date(),
            ttlSeconds: ttl ?? configuration.defaultTTL
        )

        storeInMemory(entry: entry, key: key)
        storeOnDisk(entry: entry, key: key)
    }

    func remove(forKey key: String) async {
        memoryCache.removeValue(forKey: key)
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")
        let metaURL = cacheDirectory.appendingPathComponent("\(key).meta")
        try? fileManager.removeItem(at: fileURL)
        try? fileManager.removeItem(at: metaURL)
    }

    func clearAll() async {
        memoryCache.removeAll()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func clearExpired() async {
        // Clear expired memory entries
        memoryCache = memoryCache.filter { !$0.value.isExpired }

        // Clear expired disk entries
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else { return }

        for file in files where file.pathExtension == "json" {
            let metaURL = file.appendingPathExtension("meta")

            var isExpired = false
            if let metaData = try? Data(contentsOf: metaURL),
               let meta = try? JSONDecoder().decode(CacheEntry<T>.self, from: metaData) {
                isExpired = meta.isExpired
            }

            if isExpired {
                try? fileManager.removeItem(at: file)
                try? fileManager.removeItem(at: metaURL)
            }
        }

        // Enforce max disk size — delete oldest accessed
        await enforceDiskSizeLimit()
    }

    // MARK: - Private

    private func storeInMemory(entry: CacheEntry<T>, key: String) {
        // LRU eviction
        if memoryCache.count >= maxMemoryEntries, let oldestKey = memoryCache.keys.first {
            memoryCache.removeValue(forKey: oldestKey)
        }
        memoryCache[key] = entry
    }

    private func storeOnDisk(entry: CacheEntry<T>, key: String) {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")
        let metaURL = cacheDirectory.appendingPathComponent("\(key).meta")

        if let data = try? JSONEncoder().encode(entry.data) {
            try? data.write(to: fileURL)
        }

        if let metaData = try? JSONEncoder().encode(entry) {
            try? metaData.write(to: metaURL)
        }
    }

    private func loadFromDisk(key: String) -> CacheEntry<T>? {
        let metaURL = cacheDirectory.appendingPathComponent("\(key).meta")
        guard let metaData = try? Data(contentsOf: metaURL),
              let entry = try? JSONDecoder().decode(CacheEntry<T>.self, from: metaData) else {
            return nil
        }

        // Load actual data from separate file
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")
        guard let data = try? Data(contentsOf: fileURL),
              let value = try? JSONDecoder().decode(T.self, from: data) else {
            return nil
        }

        return CacheEntry(data: value, cachedAt: entry.cachedAt, ttlSeconds: entry.ttlSeconds)
    }

    private func enforceDiskSizeLimit() async {
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else { return }

        var totalSize: Int64 = 0
        var fileInfos: [FileInfo] = []

        for file in files {
            guard file.pathExtension == "json" else { continue }
            let attributes = try? fileManager.attributesOfItem(atPath: file.path)
            let size = (attributes?[FileAttributeKey.size] as? Int64) ?? 0
            let date = (attributes?[FileAttributeKey.modificationDate] as? Date) ?? Date.distantPast
            totalSize += size
            fileInfos.append(FileInfo(url: file, size: size, date: date))
        }

        let limitBytes = Int64(configuration.maxDiskSizeMB * 1024 * 1024)
        guard totalSize > limitBytes else { return }

        // Sort by modification date (oldest first) and delete until under limit
        let sorted = fileInfos.sorted { $0.date < $1.date }
        var currentSize = totalSize

        for info in sorted {
            guard currentSize > limitBytes else { break }
            try? fileManager.removeItem(at: info.url)
            let metaURL = info.url.deletingPathExtension().appendingPathExtension("meta")
            try? fileManager.removeItem(at: metaURL)
            currentSize -= info.size
        }
    }
}
