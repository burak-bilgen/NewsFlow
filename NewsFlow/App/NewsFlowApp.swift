import SwiftUI

@main
struct NewsFlowApp: App {
    @StateObject private var container = AppContainer.make()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var languageManager = LanguageManager()
    private let imageCache: ImageCacheServicing = ImageCacheAdapter()

    init() {
        AppLaunchMetrics.startTracking()
        BackgroundRefreshManager.shared.register()
        MemoryWarningHandler.shared.startMonitoring()
        MemoryWarningHandler.shared.onMemoryWarning = { [imageCache] in
            Task {
                await imageCache.clearMemory()
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootNavigationView(container: container)
                .environmentObject(themeManager)
                .environmentObject(languageManager)
                .environment(\.imageCache, imageCache)
                .preferredColorScheme(themeManager.currentTheme.colorScheme)
                .offlineAware()
        }
    }
}
