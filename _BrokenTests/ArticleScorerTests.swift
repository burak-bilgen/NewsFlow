import XCTest
@testable import NewsApto

final class SmartArticleScorerTests: XCTestCase {
    private let now = Date()

    func testRecencyScoreLessThanOneHour() {
        let article = TestFactory.article(id: "1", title: "Recent", publishedAt: now.addingTimeInterval(-1800))
        let scorer = SmartArticleScorer(now: now)
        let scored = scorer.score([article])
        XCTAssertEqual(scored.first?.score, 40 + 3)
    }

    func testRecencyScoreOneToThreeHours() {
        let article = TestFactory.article(id: "1", title: "Few hours ago", publishedAt: now.addingTimeInterval(-7200))
        let scorer = SmartArticleScorer(now: now)
        let scored = scorer.score([article])
        XCTAssertEqual(scored.first?.score, 35 + 3)
    }

    func testRecencyScoreThreeToSixHours() {
        let article = TestFactory.article(id: "1", title: "Six hours ago", publishedAt: now.addingTimeInterval(-14400))
        let scorer = SmartArticleScorer(now: now)
        let scored = scorer.score([article])
        XCTAssertEqual(scored.first?.score, 30 + 3)
    }

    func testRecencyScoreSixToTwelveHours() {
        let article = TestFactory.article(id: "1", title: "Twelve hours title for testing", publishedAt: now.addingTimeInterval(-36000))
        let scorer = SmartArticleScorer(now: now)
        let scored = scorer.score([article])
        XCTAssertEqual(scored.first?.score, 25 + 7)
    }

    func testRecencyScoreOneToTwoDays() {
        let article = TestFactory.article(id: "1", title: "Day old", publishedAt: now.addingTimeInterval(-86400 * 1.5))
        let scorer = SmartArticleScorer(now: now)
        let scored = scorer.score([article])
        XCTAssertEqual(scored.first?.score, 12 + 3)
    }

    func testRecencyScoreTwoToThreeDays() {
        let article = TestFactory.article(id: "1", title: "Old article", publishedAt: now.addingTimeInterval(-86400 * 2.5))
        let scorer = SmartArticleScorer(now: now)
        let scored = scorer.score([article])
        XCTAssertEqual(scored.first?.score, 6 + 3)
    }

    func testRecencyScoreMoreThanThreeDays() {
        let article = TestFactory.article(id: "1", title: "Very old", publishedAt: now.addingTimeInterval(-86400 * 10))
        let scorer = SmartArticleScorer(now: now)
        let scored = scorer.score([article])
        XCTAssertEqual(scored.first?.score, 2 + 3)
    }

    func testRecencyScoreNilDate() {
        let article = TestFactory.article(id: "1", title: "No date", publishedAt: nil)
        let scorer = SmartArticleScorer(now: now)
        let scored = scorer.score([article])
        XCTAssertEqual(scored.first?.score, 0 + 3)
    }

    func testContentScoreWithImage() {
        let article = Article(id: "1", sourceID: "test", title: "Test", imageURL: URL(string: "https://example.com/img.jpg"))
        let scorer = SmartArticleScorer(now: now)
        let scored = scorer.score([article])
        XCTAssertEqual(scored.first?.score, 0 + 15 + 3)
    }

    func testContentScoreWithDescription() {
        let article = Article(id: "1", sourceID: "test", title: "Test", description: String(repeating: "a", count: 100))
        let scorer = SmartArticleScorer(now: now)
        let scored = scorer.score([article])
        XCTAssertEqual(scored.first?.score, 0 + 5 + 3)
    }

    func testContentScoreWithSnippet() {
        let article = Article(id: "1", sourceID: "test", title: "Test", contentSnippet: "Snippet text")
        let scorer = SmartArticleScorer(now: now)
        let scored = scorer.score([article])
        XCTAssertEqual(scored.first?.score, 0 + 5 + 3)
    }

    func testTitleScoreShortTitle() {
        let article = Article(id: "1", sourceID: "test", title: "Short")
        let scorer = SmartArticleScorer(now: now)
        let scored = scorer.score([article])
        XCTAssertEqual(scored.first?.score, 0 + 3)
    }

    func testTitleScoreMediumTitle() {
        let article = Article(id: "1", sourceID: "test", title: "This is a medium length title test")
        let scorer = SmartArticleScorer(now: now)
        let scored = scorer.score([article])
        XCTAssertEqual(scored.first?.score, 0 + 7)
    }

    func testTitleScoreLongTitle() {
        let article = Article(id: "1", sourceID: "test", title: String(repeating: "a", count: 50))
        let scorer = SmartArticleScorer(now: now)
        let scored = scorer.score([article])
        XCTAssertEqual(scored.first?.score, 0 + 12)
    }

    func testTitleScoreVeryLongTitle() {
        let article = Article(id: "1", sourceID: "test", title: String(repeating: "a", count: 100))
        let scorer = SmartArticleScorer(now: now)
        let scored = scorer.score([article])
        XCTAssertEqual(scored.first?.score, 0 + 15)
    }

    func testTitleScoreEmptyTitle() {
        let article = Article(id: "1", sourceID: "test", title: "")
        let scorer = SmartArticleScorer(now: now)
        let scored = scorer.score([article])
        XCTAssertEqual(scored.first?.score, 0)
    }

    func testSortAndDeduplicateOrdersByScore() {
        let highScore = Article(id: "1", sourceID: "test", title: "High score recent", publishedAt: now)
        let lowScore = Article(id: "2", sourceID: "test", title: "Low", publishedAt: now.addingTimeInterval(-86400 * 10))
        let scorer = SmartArticleScorer(now: now)

        let result = scorer.sortAndDeduplicate([lowScore, highScore])

        XCTAssertEqual(result.map(\.id), ["1", "2"])
    }

    func testSortAndDeduplicateRemovesDuplicates() {
        let article1 = Article(id: "1", sourceID: "test", title: "Duplicate", publishedAt: now)
        let article2 = Article(id: "1", sourceID: "test", title: "Duplicate", publishedAt: now)
        let scorer = SmartArticleScorer(now: now)

        let result = scorer.sortAndDeduplicate([article1, article2])

        XCTAssertEqual(result.count, 1)
    }

    func testSortAndDeduplicateHandlesEmpty() {
        let scorer = SmartArticleScorer(now: now)
        let result = scorer.sortAndDeduplicate([])
        XCTAssertTrue(result.isEmpty)
    }

    func testScoredArticleEqualityById() {
        let article1 = Article(id: "1", sourceID: "test", title: "A")
        let article2 = Article(id: "1", sourceID: "test", title: "B")
        let scored1 = ScoredArticle(article: article1, score: 10)
        let scored2 = ScoredArticle(article: article2, score: 20)

        XCTAssertEqual(scored1, scored2)
    }
}
