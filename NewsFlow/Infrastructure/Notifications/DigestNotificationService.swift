import UserNotifications
import Foundation

enum DigestFrequency: String, CaseIterable, Codable {
    case off = "off"
    case once = "once"
    case twice = "twice"
    case threeTimes = "threeTimes"

    var localizedKey: String {
        switch self {
        case .off: return "notifications.frequency.off"
        case .once: return "notifications.frequency.once"
        case .twice: return "notifications.frequency.twice"
        case .threeTimes: return "notifications.frequency.threeTimes"
        }
    }

    var notificationCount: Int {
        switch self {
        case .off: return 0
        case .once: return 1
        case .twice: return 2
        case .threeTimes: return 3
        }
    }
}

final class DigestNotificationService {
    static let shared = DigestNotificationService()
    private let center = UNUserNotificationCenter.current()
    private let defaults = UserDefaults.standard

    private let frequencyKey = "digestFrequency"
    private let lastDigestDatesKey = "lastDigestDates"

    var frequency: DigestFrequency {
        get {
            guard let raw = defaults.string(forKey: frequencyKey) else { return .once }
            return DigestFrequency(rawValue: raw) ?? .once
        }
        set { defaults.set(newValue.rawValue, forKey: frequencyKey) }
    }

    private var lastDigestDates: [String: Date] {
        get {
            guard let data = defaults.data(forKey: lastDigestDatesKey),
                  let dict = try? JSONDecoder().decode([String: Date].self, from: data) else {
                return [:]
            }
            return dict
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: lastDigestDatesKey)
            }
        }
    }

    private init() {}

    func requestAuthorization() async -> Bool {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        do {
            let granted = try await center.requestAuthorization(options: options)
            if granted {
                NewsFlowLogger.shared.info("Notification authorization granted", category: "Notifications")
            }
            return granted
        } catch {
            NewsFlowLogger.shared.error("Notification auth failed: \(error.localizedDescription)", category: "Notifications")
            return false
        }
    }

    func scheduleDigestIfNeeded(articles: [Article]) async {
        guard frequency != .off else { return }
        guard !articles.isEmpty else { return }

        let importantArticles = filterImportantArticles(articles)
        guard !importantArticles.isEmpty else {
            NewsFlowLogger.shared.info("No important articles to notify about", category: "Notifications")
            return
        }

        let todayKey = dateKey(Date())

        if let lastSent = lastDigestDates[todayKey] {
            let todayStart = Calendar.current.startOfDay(for: Date())
            if lastSent > todayStart {
                NewsFlowLogger.shared.debug("Digest already sent today, skipping", category: "Notifications")
                return
            }
        }

        let times = scheduledTimes(for: frequency)
        for time in times {
            await scheduleDigest(articles: importantArticles, at: time)
        }

        lastDigestDates[todayKey] = Date()
        NewsFlowLogger.shared.info("Scheduled \(times.count) digest notifications for today", category: "Notifications")
    }

    private func scheduleDigest(articles: [Article], at time: DateComponents) async {
        let title = digestTitle(articles: articles)
        let body = digestBody(articles: articles)

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = NSNumber(value: articles.count)
        content.userInfo = ["type": "digest"]

        if let topArticle = articles.first, let articleURL = topArticle.url {
            content.userInfo["url"] = articleURL.absoluteString
            content.userInfo["articleID"] = topArticle.id
        }

        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: false)
        let identifier = "digest-\(dateKey(Date()))-\(time.hour ?? 0)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await center.add(request)
            NewsFlowLogger.shared.debug("Digest scheduled at \(time.hour ?? 0):00", category: "Notifications")
        } catch {
            NewsFlowLogger.shared.error("Failed to schedule digest: \(error.localizedDescription)", category: "Notifications")
        }
    }

    func removeAllPending() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    // MARK: - Helpers

    private func filterImportantArticles(_ articles: [Article]) -> [Article] {
        articles.filter { article in
            if article.title.contains("Breaking") || article.title.contains("Exclusive") || article.title.contains("Urgent") {
                return true
            }
            if article.title.hasPrefix("BREAKING") || article.title.hasPrefix("JUST IN") {
                return true
            }
            if let description = article.description, description.count > 80 {
                return true
            }
            return false
        }
    }

    private func digestTitle(articles: [Article]) -> String {
        if articles.count == 1 {
            return L10n.text("digest.breaking.title", String(articles[0].title.prefix(60)))
        }
        return L10n.text("digest.multi.title", articles.count)
    }

    private func digestBody(articles: [Article]) -> String {
        let top = articles.prefix(3)
        return top.map { L10n.text("digest.bullet", String($0.title.prefix(80))) }.joined(separator: "\n")
    }

    private func scheduledTimes(for frequency: DigestFrequency) -> [DateComponents] {
        let calendar = Calendar.current
        let now = calendar.dateComponents([.hour, .minute], from: Date())
        let currentHour = now.hour ?? 8

        switch frequency {
        case .off: return []
        case .once:
            let hour = max(currentHour + 2, 8)
            return [DateComponents(hour: min(hour, 20), minute: 0)]
        case .twice:
            let morning = max(currentHour + 1, 8)
            let evening = min(morning + 6, 20)
            return [DateComponents(hour: min(morning, 12), minute: 0), DateComponents(hour: evening, minute: 0)]
        case .threeTimes:
            let base = max(currentHour + 1, 8)
            return [
                DateComponents(hour: min(base, 10), minute: 0),
                DateComponents(hour: min(base + 4, 16), minute: 0),
                DateComponents(hour: min(base + 8, 20), minute: 0)
            ]
        }
    }

    private func dateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
