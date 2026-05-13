import Foundation
import UserNotifications

final class SentinelNotificationService {
    static let shared = SentinelNotificationService()
    private let center = UNUserNotificationCenter.current()
    private let defaults = UserDefaults.standard
    private let maxDailyAlerts = 3
    private let sentinelKey = "sentinel.count"
    private let sentinelDateKey = "sentinel.date"

    private init() {}

    var todayCount: Int {
        let today = dateKey(Date())
        guard defaults.string(forKey: sentinelDateKey) == today else { return 0 }
        return defaults.integer(forKey: sentinelKey)
    }

    func evaluateAndNotify(articles: [Article]) async {
        let today = dateKey(Date())
        if defaults.string(forKey: sentinelDateKey) != today {
            defaults.set(0, forKey: sentinelKey)
            defaults.set(today, forKey: sentinelDateKey)
        }

        guard todayCount < maxDailyAlerts else { return }

        let important = articles.filter { scoreArticle($0) >= 9 }

        for article in important.prefix(maxDailyAlerts - todayCount) {
            let title = generateTitle(article)
            await schedule(title: title, articleID: article.id)
            var count = todayCount
            count += 1
            defaults.set(count, forKey: sentinelKey)
        }
    }

    private func scoreArticle(_ article: Article) -> Int {
        var score = 0
        let title = article.title.lowercased()
        if title.contains("breaking") || title.contains("just in") || title.contains("urgent") { score += 4 }
        if title.contains("exclusive") || title.contains("developing") { score += 3 }
        if let desc = article.description, desc.count > 100 { score += 2 }
        if article.imageURL != nil { score += 1 }
        return score
    }

    private func generateTitle(_ article: Article) -> String {
        let words = article.title.split(separator: " ")
        let truncated = words.prefix(6).joined(separator: " ")
        return "> SENTINEL: \(truncated)"
    }

    private func schedule(title: String, articleID: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = "Tap to read"
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.threadIdentifier = "sentinel"
        content.userInfo = ["type": "sentinel", "articleID": articleID]

        let request = UNNotificationRequest(identifier: "sentinel-\(articleID)", content: content, trigger: nil)
        try? await center.add(request)
    }

    func requestAuthorization() async {
        let options: UNAuthorizationOptions = [.alert, .sound]
        _ = try? await center.requestAuthorization(options: options)
    }

    private func dateKey(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: date)
    }
}
