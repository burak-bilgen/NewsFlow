import XCTest
@testable import NewsApto

final class ReadingListRepositoryTests: XCTestCase {
    func testAddRemoveAndIsSavedPersistenceBehavior() async throws {
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: "NewsAptoTests.\(UUID().uuidString)"))
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
        let savedArticles = await repository.savedArticles()
        XCTAssertTrue(savedAfterAdd)
        XCTAssertEqual(savedIDs, Set([article.id]))
        XCTAssertEqual(savedArticles, [article])

        try await repository.remove(articleID: article.id)
        let savedAfterRemove = await repository.isSaved(articleID: article.id)
        XCTAssertFalse(savedAfterRemove)
    }

    func testSavedArticlesAreReturnedNewestFirst() async throws {
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: "NewsAptoTests.\(UUID().uuidString)"))
        let repository = UserDefaultsReadingListRepository(userDefaults: userDefaults)
        defer {
            userDefaults.removeObject(forKey: UserDefaultsReadingListRepository.storageKey)
        }

        let older = TestFactory.article(
            id: "older",
            title: "Older",
            publishedAt: Date(timeIntervalSince1970: 100)
        )
        let newer = TestFactory.article(
            id: "newer",
            title: "Newer",
            publishedAt: Date(timeIntervalSince1970: 200)
        )

        try await repository.add(older)
        try await repository.add(newer)

        let savedArticles = await repository.savedArticles()
        XCTAssertEqual(savedArticles.map(\.id), ["newer", "older"])
    }
}
