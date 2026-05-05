import Foundation
import OSLog

// MARK: - Log Level

enum LogLevel: Int, Comparable {
    case verbose = 0
    case debug = 1
    case info = 2
    case warning = 3
    case error = 4
    case critical = 5

    var osLogType: OSLogType {
        switch self {
        case .verbose, .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .critical: return .fault
        }
    }

    var emoji: String {
        switch self {
        case .verbose: return "💬"
        case .debug: return "🐛"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .critical: return "🚨"
        }
    }

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Log Entry

struct LogEntry {
    let timestamp: Date
    let level: LogLevel
    let message: String
    let category: String
    let file: String
    let function: String
    let line: Int
    let metadata: [String: Any]?
}

// MARK: - Logger Protocol

protocol Logging {
    func log(_ level: LogLevel, _ message: String, category: String, file: String, function: String, line: Int, metadata: [String: Any]?)
}

extension Logging {
    func verbose(_ message: String, category: String = "App", file: String = #file, function: String = #function, line: Int = #line, metadata: [String: Any]? = nil) {
        log(.verbose, message, category: category, file: file, function: function, line: line, metadata: metadata)
    }

    func debug(_ message: String, category: String = "App", file: String = #file, function: String = #function, line: Int = #line, metadata: [String: Any]? = nil) {
        log(.debug, message, category: category, file: file, function: function, line: line, metadata: metadata)
    }

    func info(_ message: String, category: String = "App", file: String = #file, function: String = #function, line: Int = #line, metadata: [String: Any]? = nil) {
        log(.info, message, category: category, file: file, function: function, line: line, metadata: metadata)
    }

    func warning(_ message: String, category: String = "App", file: String = #file, function: String = #function, line: Int = #line, metadata: [String: Any]? = nil) {
        log(.warning, message, category: category, file: file, function: function, line: line, metadata: metadata)
    }

    func error(_ message: String, category: String = "App", file: String = #file, function: String = #function, line: Int = #line, metadata: [String: Any]? = nil) {
        log(.error, message, category: category, file: file, function: function, line: line, metadata: metadata)
    }

    func critical(_ message: String, category: String = "App", file: String = #file, function: String = #function, line: Int = #line, metadata: [String: Any]? = nil) {
        log(.critical, message, category: category, file: file, function: function, line: line, metadata: metadata)
    }
}

// MARK: - Console Logger

final class ConsoleLogger: Logging {
    var minimumLevel: LogLevel = .debug

    func log(_ level: LogLevel, _ message: String, category: String, file: String, function: String, line: Int, metadata: [String: Any]?) {
        guard level >= minimumLevel else { return }

        let filename = (file as NSString).lastPathComponent
        let timestamp = ISO8601DateFormatter().string(from: Date())
        var output = "\(level.emoji) [\(timestamp)] [\(category)] [\(filename):\(line)] \(function) — \(message)"

        if let metadata = metadata, !metadata.isEmpty {
            let metaString = metadata.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            output += " | Metadata: {\(metaString)}"
        }

        #if DEBUG
        print(output)
        #endif

        // Also send to unified logging
        let osLog = OSLog(subsystem: "burakbilgen.NewsFlow", category: category)
        os_log("%{public}@", log: osLog, type: level.osLogType, output)
    }
}

// MARK: - NewsFlow Logger

/// Centralized logger for the entire app.
/// Injects into ViewModels, Use Cases, and Services for consistent logging.
@MainActor
final class NewsFlowLogger: Logging {
    static let shared = NewsFlowLogger()

    private let logger: Logging

    init(logger: Logging = ConsoleLogger()) {
        self.logger = logger
    }

    func log(_ level: LogLevel, _ message: String, category: String, file: String, function: String, line: Int, metadata: [String: Any]?) {
        logger.log(level, message, category: category, file: file, function: function, line: line, metadata: metadata)
    }
}
