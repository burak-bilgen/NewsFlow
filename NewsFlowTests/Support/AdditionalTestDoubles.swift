import Foundation
@testable import NewsFlow

// MARK: - Failing Reading List Repository

actor FailingReadingListRepository: ReadingListRepositoryProtocol {
    func savedArticleIDs() async -> Set<String> { [] }
    func isSaved(articleID: String) async -> Bool { false }
    func add(_ article: Article) async throws {
        throw NSError(domain: "test", code: 1)
    }
    func remove(articleID: String) async throws {
        throw NSError(domain: "test", code: 1)
    }
}

// MARK: - Delayed Articles Repository

final class DelayedArticlesRepositorySpy: ArticlesRepositoryProtocol {
    var result: Result<[Article], Error>
    var delayNanoseconds: UInt64
    private(set) var requestCount = 0

    init(result: Result<[Article], Error>, delayNanoseconds: UInt64 = 100_000_000) {
        self.result = result
        self.delayNanoseconds = delayNanoseconds
    }

    func fetchArticles(sourceID: String, page: Int, pageSize: Int) async throws -> PaginatedResult<Article> {
        requestCount += 1
        try await Task.sleep(nanoseconds: delayNanoseconds)
        let items = try result.get()
        return PaginatedResult(
            items: items,
            currentPage: page,
            hasMorePages: items.count >= pageSize
        )
    }
}

// MARK: - Delayed Sources Repository

final class DelayedSourcesRepositorySpy: SourcesRepositoryProtocol {
    var result: Result<[NewsSource], Error>
    var delayNanoseconds: UInt64
    private(set) var requestCount = 0

    init(result: Result<[NewsSource], Error>, delayNanoseconds: UInt64 = 100_000_000) {
        self.result = result
        self.delayNanoseconds = delayNanoseconds
    }

    func fetchSources() async throws -> [NewsSource] {
        requestCount += 1
        try await Task.sleep(nanoseconds: delayNanoseconds)
        return try result.get()
    }
}
