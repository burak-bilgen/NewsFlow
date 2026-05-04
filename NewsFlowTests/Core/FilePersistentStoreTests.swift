import XCTest
@testable import NewsFlow

final class FilePersistentStoreTests: XCTestCase {
    private var tempDir: URL!
    private var store: FilePersistentStore!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        store = try FilePersistentStore(fileManager: FileManager.default, baseURL: tempDir)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    func testSaveAndLoad() async throws {
        let sources = [
            NewsSource(id: "bbc", name: "BBC", description: "News", category: "general", language: "en", url: nil)
        ]
        try await store.save(sources, forKey: "sources")

        let loaded: [NewsSource]? = await store.load([NewsSource].self, forKey: "sources")
        XCTAssertEqual(loaded?.count, 1)
        XCTAssertEqual(loaded?.first?.id, "bbc")
    }

    func testLoadReturnsNilForMissingKey() async {
        let loaded: [NewsSource]? = await store.load([NewsSource].self, forKey: "missing")
        XCTAssertNil(loaded)
    }

    func testRemoveDeletesData() async throws {
        let sources = [
            NewsSource(id: "bbc", name: "BBC", description: "News", category: "general", language: "en", url: nil)
        ]
        try await store.save(sources, forKey: "sources")
        await store.remove(forKey: "sources")

        let loaded: [NewsSource]? = await store.load([NewsSource].self, forKey: "sources")
        XCTAssertNil(loaded)
    }

    func testLastUpdatedReturnsDateAfterSave() async throws {
        let sources = [
            NewsSource(id: "bbc", name: "BBC", description: "News", category: "general", language: "en", url: nil)
        ]
        let before = Date()
        try await store.save(sources, forKey: "sources")
        let after = Date()

        let lastUpdated = await store.lastUpdated(forKey: "sources")
        XCTAssertNotNil(lastUpdated)
        XCTAssertTrue(lastUpdated! >= before)
        XCTAssertTrue(lastUpdated! <= after)
    }

    func testLastUpdatedReturnsNilForMissingKey() async {
        let lastUpdated = await store.lastUpdated(forKey: "missing")
        XCTAssertNil(lastUpdated)
    }

    func testOverwriteExistingKey() async throws {
        let first = [
            NewsSource(id: "bbc", name: "BBC", description: "News", category: "general", language: "en", url: nil)
        ]
        let second = [
            NewsSource(id: "cnn", name: "CNN", description: "News", category: "general", language: "en", url: nil)
        ]

        try await store.save(first, forKey: "sources")
        try await store.save(second, forKey: "sources")

        let loaded: [NewsSource]? = await store.load([NewsSource].self, forKey: "sources")
        XCTAssertEqual(loaded?.count, 1)
        XCTAssertEqual(loaded?.first?.id, "cnn")
    }
}
