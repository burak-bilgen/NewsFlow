import Foundation
import OSLog

// MARK: - App Launch Metrics

/// Tracks and reports app launch performance metrics.
/// Helps identify regressions in cold start time.
enum AppLaunchMetrics {
    private static var launchStartTime: Date?
    private static let suiteName = "burakbilgen.NewsFlow.metrics"
    private static let lastLaunchKey = "lastLaunchTime"
    private static let launchCountKey = "launchCount"

    private static let logger = Logger(subsystem: "burakbilgen.NewsFlow", category: "LaunchMetrics")

    /// Call this from `NewsFlowApp.init()` to begin tracking.
    static func startTracking() {
        launchStartTime = Date()
    }

    /// Call this from the first view's `.onAppear` to record completion.
    static func recordLaunchCompleted() {
        guard let startTime = launchStartTime else { return }
        launchStartTime = nil

        let launchTime = Date().timeIntervalSince(startTime)
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard

        defaults.set(launchTime, forKey: lastLaunchKey)
        let count = defaults.integer(forKey: launchCountKey) + 1
        defaults.set(count, forKey: launchCountKey)

        logger.info("App launch completed in \(String(format: "%.3f", launchTime))s (launch #\(count))")

        // Warn if launch time exceeds 2 seconds
        if launchTime > 2.0 {
            logger.warning("Slow launch detected: \(String(format: "%.3f", launchTime))s")
        }
    }

    static var lastLaunchTime: TimeInterval? {
        UserDefaults(suiteName: suiteName)?.double(forKey: lastLaunchKey)
    }

    static var launchCount: Int {
        UserDefaults(suiteName: suiteName)?.integer(forKey: launchCountKey) ?? 0
    }
}
