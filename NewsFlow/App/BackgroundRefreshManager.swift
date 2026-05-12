import BackgroundTasks
import Foundation

final class BackgroundRefreshManager {
    static let shared = BackgroundRefreshManager()
    static let taskIdentifier = "burakbilgen.NewsFlow.refresh"

    private init() {}

    func register() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdentifier,
            using: nil
        ) { [weak self] task in
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            self?.handleRefresh(task: refreshTask)
        }
    }

    func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
            NewsFlowLogger.shared.info("Scheduled background refresh", category: "Background")
        } catch {
            NewsFlowLogger.shared.error("Failed to schedule: \(error.localizedDescription)", category: "Background")
        }
    }

    private func handleRefresh(task: BGAppRefreshTask) {
        schedule()

        let refreshTask = Task { [weak self] in
            await self?.performRefresh()
            task.setTaskCompleted(success: !Task.isCancelled)
        }

        task.expirationHandler = {
            refreshTask.cancel()
        }
    }

    private func performRefresh() async {
        NewsFlowLogger.shared.info("Background refresh executed", category: "Background")

        guard DigestNotificationService.shared.frequency != .off else {
            NewsFlowLogger.shared.info("Digest notifications disabled, skipping", category: "Notifications")
            return
        }

        do {
            let requestBuilder = NewsAPIRequestBuilder()
            let client = NewsAPIClient(requestBuilder: requestBuilder)
            let retryingClient = RetryingNewsAPIClientDecorator(client: client)
            let newsAPIRepo = NewsAPIArticlesRepository(client: retryingClient)
            let guardianClient = GuardianClient()
            let nytClient = NYTClient()
            let aggregateRepo = AggregateArticlesRepository(
                newsAPIRepository: newsAPIRepo,
                guardianClient: guardianClient,
                nytClient: nytClient
            )

            let result = try await aggregateRepo.fetchAllArticles(page: 1, pageSize: 10)
            await DigestNotificationService.shared.scheduleDigestIfNeeded(articles: result.items)

            NewsFlowLogger.shared.info("Background digest check completed", category: "Notifications")
        } catch {
            NewsFlowLogger.shared.error("Background refresh fetch failed: \(error.localizedDescription)", category: "Background")
        }
    }
}
