import XCTest
@testable import NewsFlow
import UIKit

@MainActor
final class ImageCacheTests: XCTestCase {
    private var cache: ImageCache!

    override func setUp() async throws {
        try await super.setUp()
        cache = ImageCache()
    }

    override func tearDown() async throws {
        await cache.clearDiskCache()
        await cache.clearMemoryCache()
        cache = nil
        try await super.tearDown()
    }

    func testImageReturnsNilForUncachedURL() async {
        let url = URL(string: "https://example.com/test.jpg")!
        let result = await cache.image(for: url, targetSize: nil)
        XCTAssertNil(result)
    }

    func testLoadImageReturnsNilForInvalidURL() async {
        let url = URL(string: "https://invalid-test-domain.example/nonexistent.jpg")!
        let result = await cache.loadImage(from: url, targetSize: nil)
        XCTAssertNil(result)
    }

    func testCacheConfigurationDefaults() {
        let config = ImageCache.Configuration()
        XCTAssertEqual(config.memoryCostLimitMB, 50)
        XCTAssertEqual(config.diskSizeLimitMB, 200)
        XCTAssertEqual(config.maxDiskAgeDays, 7)
    }
}
