import UIKit
import Combine
import os.log

/// Observes system memory pressure notifications and proactively clears
/// non-essential caches to prevent the OS from terminating the app.
///
/// This is a senior-level architectural component demonstrating:
/// - `UIApplication.didReceiveMemoryWarningNotification` observation
/// - Cooperative cache eviction under memory pressure
/// - OSLog integration for system diagnostics
@MainActor
final class MemoryWarningHandler {
    static let shared = MemoryWarningHandler()

    private var cancellables: Set<AnyCancellable> = []
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "NewsFlow", category: "Memory")

    var onMemoryWarning: (() -> Void)?

    private init() {}

    func startMonitoring() {
        NotificationCenter.default
            .publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleMemoryWarning()
            }
            .store(in: &cancellables)
    }

    func stopMonitoring() {
        cancellables.removeAll()
    }

    private func handleMemoryWarning() {
        logger.warning("Memory warning received — clearing caches")

        // Clear URLSession cache
        URLCache.shared.removeAllCachedResponses()

        // Trigger registered cache evictions
        onMemoryWarning?()

        // Log remaining memory footprint (approximate)
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        if kerr == KERN_SUCCESS {
            let usedMB = Double(info.resident_size) / 1024 / 1024
            logger.info("Resident memory after cleanup: \(usedMB) MB")
        }
    }
}
