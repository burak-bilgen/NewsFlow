import Foundation

// MARK: - Crash Reporting Protocol

/// Abstraction for crash reporting services (Firebase Crashlytics, Sentry, etc.).
/// Allows the app to record breadcrumbs and non-fatal errors without hardcoding a specific provider.
protocol CrashReporting {
    func recordBreadcrumb(_ message: String, category: String, metadata: [String: Any]?)
    func recordError(_ error: Error, metadata: [String: Any]?)
    func setUserIdentifier(_ identifier: String)
    func setCustomValue(_ value: Any, forKey key: String)
}

// MARK: - Console Crash Reporter (Default / Debug)

/// Fallback crash reporter that logs to the console via NewsFlowLogger.
/// Used when no third-party crash reporter is configured.
final class ConsoleCrashReporter: CrashReporting {
    func recordBreadcrumb(_ message: String, category: String, metadata: [String: Any]?) {
        var logMessage = "🍞 [Breadcrumb] [\(category)] \(message)"
        if let metadata = metadata, !metadata.isEmpty {
            let metaString = metadata.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            logMessage += " | Metadata: {\(metaString)}"
        }
        NewsFlowLogger.shared.info(logMessage, category: "CrashReporter")
    }

    func recordError(_ error: Error, metadata: [String: Any]?) {
        var logMessage = "💥 [Non-Fatal Error] \(error.localizedDescription)"
        if let metadata = metadata, !metadata.isEmpty {
            let metaString = metadata.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            logMessage += " | Metadata: {\(metaString)}"
        }
        NewsFlowLogger.shared.error(logMessage, category: "CrashReporter")
    }

    func setUserIdentifier(_ identifier: String) {
        NewsFlowLogger.shared.info("User ID set: \(identifier)", category: "CrashReporter")
    }

    func setCustomValue(_ value: Any, forKey key: String) {
        NewsFlowLogger.shared.info("Custom value [\(key)]: \(value)", category: "CrashReporter")
    }
}

// MARK: - Global Crash Reporter

/// Centralized crash reporter instance.
/// Replace `ConsoleCrashReporter()` with `FirebaseCrashReporter()` or `SentryReporter()` when integrating a third-party service.
enum CrashReporter {
    static var shared: CrashReporting = ConsoleCrashReporter()
}
