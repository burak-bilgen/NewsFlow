import SwiftUI

@main
struct NewsFlowApp: App {
    @StateObject private var container = AppContainer.make()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var languageManager = LanguageManager()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    private let imageCache: ImageCacheServicing = ImageCacheAdapter()

    init() {
        AppLaunchMetrics.startTracking()
        BackgroundRefreshManager.shared.register()
        BackgroundRefreshManager.shared.schedule()
        MemoryWarningHandler.shared.startMonitoring()
        MemoryWarningHandler.shared.onMemoryWarning = { [imageCache] in
            Task {
                await imageCache.clearMemory()
            }
        }

        if DigestNotificationService.shared.frequency != .off {
            Task { await DigestNotificationService.shared.requestAuthorization() }
        }
    }

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding || ProcessInfo.processInfo.arguments.contains("UITest.MockNews") {
                RootNavigationView(container: container)
                    .environmentObject(themeManager)
                    .environmentObject(languageManager)
                    .environment(\.imageCache, imageCache)
                    .preferredColorScheme(themeManager.currentTheme.colorScheme)
                    .onOpenURL { url in
                        _ = DeepLinkHandler.shared.handle(url)
                    }
            } else {
                OnboardingView()
            }
        }
    }
}
