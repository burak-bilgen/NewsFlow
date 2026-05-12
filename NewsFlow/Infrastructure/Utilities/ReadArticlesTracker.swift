import Foundation

actor ReadArticlesTracker {
    static let shared = ReadArticlesTracker()
    private let defaults = UserDefaults.standard
    private let storageKey = "readArticles"

    private var readIDs: Set<String> {
        get { Set(defaults.stringArray(forKey: storageKey) ?? []) }
        set { defaults.set(Array(newValue), forKey: storageKey) }
    }

    func markAsRead(_ articleID: String) {
        var ids = readIDs
        ids.insert(articleID)
        readIDs = ids
    }

    func isRead(_ articleID: String) -> Bool {
        readIDs.contains(articleID)
    }

    func markAsUnread(_ articleID: String) {
        var ids = readIDs
        ids.remove(articleID)
        readIDs = ids
    }

    func clearAll() {
        defaults.removeObject(forKey: storageKey)
    }

    nonisolated func markAsReadNonisolated(_ articleID: String) {
        Task { await markAsRead(articleID) }
    }
}
