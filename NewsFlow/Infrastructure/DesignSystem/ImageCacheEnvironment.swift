import SwiftUI

// MARK: - ImageCache Environment Key

/// Allows ImageCacheService to be injected via the SwiftUI environment
/// rather than using a singleton. This makes views testable and
/// follows dependency injection best practices.
private struct ImageCacheKey: EnvironmentKey {
    static let defaultValue: ImageCacheServicing = ImageCacheService()
}

extension EnvironmentValues {
    var imageCache: ImageCacheServicing {
        get { self[ImageCacheKey.self] }
        set { self[ImageCacheKey.self] = newValue }
    }
}
