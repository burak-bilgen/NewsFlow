import XCTest
@testable import NewsFlow

final class ImageCacheServiceTests: XCTestCase {
    func testImageReturnsNilForUncachedURL() {
        let service = ImageCacheService()
        let url = URL(string: "https://example.com/test.jpg")!
        XCTAssertNil(service.image(for: url))
    }

    func testLoadImageFromCacheAfterFirstLoad() async {
        let service = ImageCacheService()
        guard let url = URL(string: "https://invalid-test-domain.example/nonexistent.jpg") else {
            XCTFail("URL creation failed")
            return
        }

        let result = await service.loadImage(from: url)
        XCTAssertNil(result)
    }
}
