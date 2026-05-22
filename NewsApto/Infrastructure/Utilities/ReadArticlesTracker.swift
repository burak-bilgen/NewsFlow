import Foundation

actor ReadArticlesTracker {
    static let shared = ReadArticlesTracker()
    private let defaults = UserDefaults.standard
    private let storageKey = "readArticles"
    private var cachedIDs: Set<String>

    init() {
        self.cachedIDs = Set(defaults.stringArray(forKey: storageKey) ?? [])
    }

    func markAsRead(_ articleID: String) {
        cachedIDs.insert(articleID)
        flush()
    }

    func isRead(_ articleID: String) -> Bool {
        cachedIDs.contains(articleID)
    }

    func markAsUnread(_ articleID: String) {
        cachedIDs.remove(articleID)
        flush()
    }

    func clearAll() {
        cachedIDs.removeAll()
        defaults.removeObject(forKey: storageKey)
    }

    nonisolated func markAsReadNonisolated(_ articleID: String) {
        Task { await markAsRead(articleID) }
    }

    private func flush() {
        defaults.set(Array(cachedIDs), forKey: storageKey)
    }
}
