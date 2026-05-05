import BackgroundTasks
import Foundation

// MARK: - Background Refresh Manager

/// Manages Background App Refresh using BGAppRefreshTask.
/// Registers, schedules, and handles background fetch operations for the latest headlines.
final class BackgroundRefreshManager {
    static let shared = BackgroundRefreshManager()
    static let taskIdentifier = "burakbilgen.NewsFlow.refresh"

    private init() {}

    // MARK: - Registration

    func register() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdentifier,
            using: nil
        ) { [weak self] task in
            self?.handleRefresh(task: task as! BGAppRefreshTask)
        }
    }

    // MARK: - Scheduling

    func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes

        do {
            try BGTaskScheduler.shared.submit(request)
            NewsFlowLogger.shared.info("Scheduled background refresh", category: "Background")
        } catch {
            NewsFlowLogger.shared.error("Failed to schedule background refresh: \(error.localizedDescription)", category: "Background")
        }
    }

    // MARK: - Handling

    private func handleRefresh(task: BGAppRefreshTask) {
        schedule() // Schedule next refresh immediately

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        let refreshOperation = BlockOperation { [weak self] in
            Task {
                await self?.performRefresh()
            }
        }

        task.expirationHandler = {
            queue.cancelAllOperations()
        }

        refreshOperation.completionBlock = {
            task.setTaskCompleted(success: !refreshOperation.isCancelled)
        }

        queue.addOperations([refreshOperation], waitUntilFinished: false)
    }

    private func performRefresh() async {
        // In a real implementation, fetch latest articles from API
        // and update local cache / push local notifications for breaking news.
        NewsFlowLogger.shared.info("Background refresh executed", category: "Background")
    }
}
