import SwiftUI

@main
struct NewsFlowApp: App {
    @StateObject private var container = AppContainer.make()
    @StateObject private var themeManager = ThemeManager()
    private let imageCache: ImageCacheServicing = ImageCacheService()

    var body: some Scene {
        WindowGroup {
            RootNavigationView(container: container)
                .environmentObject(themeManager)
                .environment(\.imageCache, imageCache)
                .preferredColorScheme(themeManager.currentTheme.colorScheme)
        }
    }
}
