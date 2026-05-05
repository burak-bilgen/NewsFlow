import XCTest
@testable import NewsFlow
import UIKit

final class ImageCacheServiceTests: XCTestCase {
    func testImageReturnsNilForUncachedURL() {
        let service = ImageCacheService()
        let url = URL(string: "https://example.com/test.jpg")!
        XCTAssertNil(service.image(for: url))
    }

    func testLoadImageCachesResultForSubsequentLookup() async {
        let url = URL(string: "https://example.com/image.png")!
        let session = ImageCacheMockSession(
            result: .success((makeTinyPNGData(), makeHTTPResponse(url: url)))
        )
        let service = ImageCacheService(session: session)

        let first = await service.loadImage(from: url)
        XCTAssertNotNil(first)

        let second = service.image(for: url)
        XCTAssertNotNil(second)
        XCTAssertTrue(first === second)
    }

    func testLoadImageReturnsNilForNon2xxResponse() async {
        let url = URL(string: "https://example.com/image.png")!
        let session = ImageCacheMockSession(
            result: .success((Data(), makeHTTPResponse(url: url, statusCode: 404)))
        )
        let service = ImageCacheService(session: session)

        let result = await service.loadImage(from: url)
        XCTAssertNil(result)
    }

    func testLoadImageReturnsNilForInvalidImageData() async {
        let url = URL(string: "https://example.com/image.png")!
        let session = ImageCacheMockSession(
            result: .success(("not an image".data(using: .utf8)!, makeHTTPResponse(url: url)))
        )
        let service = ImageCacheService(session: session)

        let result = await service.loadImage(from: url)
        XCTAssertNil(result)
    }

    func testLoadImageReturnsNilForNetworkError() async {
        let url = URL(string: "https://example.com/image.png")!
        let session = ImageCacheMockSession(
            result: .failure(URLError(.notConnectedToInternet))
        )
        let service = ImageCacheService(session: session)

        let result = await service.loadImage(from: url)
        XCTAssertNil(result)
    }
}

// MARK: - Helpers

private actor ImageCacheMockSession: URLSessionProtocol {
    var result: Result<(Data, URLResponse), Error>

    init(result: Result<(Data, URLResponse), Error>) {
        self.result = result
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try result.get()
    }
}

private func makeHTTPResponse(url: URL, statusCode: Int = 200) -> HTTPURLResponse {
    HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
}

private func makeTinyPNGData() -> Data {
    // 1x1 transparent PNG
    Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==")!
}
