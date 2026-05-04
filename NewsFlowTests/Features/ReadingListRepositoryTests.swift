import XCTest
@testable import NewsFlow

final class ReadingListRepositoryTests: XCTestCase {
    func testAddRemoveAndIsSavedPersistenceBehavior() async throws {
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: "NewsFlowTests.\(UUID().uuidString)"))
        let repository = UserDefaultsReadingListRepository(userDefaults: userDefaults)
        let article = TestFactory.article(id: "article-1", title: "Saved", publishedAt: Date())
        defer {
            userDefaults.removeObject(forKey: UserDefaultsReadingListRepository.storageKey)
        }

        let initiallySaved = await repository.isSaved(articleID: article.id)
        XCTAssertFalse(initiallySaved)

        try await repository.add(article)
        let savedAfterAdd = await repository.isSaved(articleID: article.id)
        let savedIDs = await repository.savedArticleIDs()
        XCTAssertTrue(savedAfterAdd)
        XCTAssertEqual(savedIDs, Set([article.id]))

        try await repository.remove(articleID: article.id)
        let savedAfterRemove = await repository.isSaved(articleID: article.id)
        XCTAssertFalse(savedAfterRemove)
    }
}
