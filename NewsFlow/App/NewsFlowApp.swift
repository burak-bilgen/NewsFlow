import SwiftUI

@main
struct NewsFlowApp: App {
    @StateObject private var container = AppContainer.make()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var imageCache = ImageCacheService()

    var body: some Scene {
        WindowGroup {
            RootNavigationView(container: container)
                .environmentObject(themeManager)
                .environmentObject(imageCache)
                .preferredColorScheme(themeManager.currentTheme.colorScheme)
        }
    }
}
