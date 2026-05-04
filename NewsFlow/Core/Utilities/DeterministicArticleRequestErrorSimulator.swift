import Foundation

protocol ArticleRequestErrorSimulating {
    func shouldSimulateError() async -> Bool
    func reset() async
}

actor EveryThirdRequestErrorSimulator: ArticleRequestErrorSimulating {
    private var requestCount = 0
    private let failingInterval: Int

    init(failingInterval: Int = 3) {
        self.failingInterval = failingInterval
    }

    func shouldSimulateError() async -> Bool {
        requestCount += 1
        return requestCount % failingInterval == 0
    }

    func reset() async {
        requestCount = 0
    }
}
