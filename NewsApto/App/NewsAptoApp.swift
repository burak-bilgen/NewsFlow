import SwiftUI

@main
struct NewsAptoApp: App {
    @StateObject private var container = AppContainer.make()
    private let imageCache: ImageCacheServicing = ImageCacheAdapter()
    @State private var showSplash = true

    init() {
        Task { await SentinelNotificationService.shared.requestAuthorization() }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView { showSplash = false }.transition(.opacity)
                } else {
                    RootNavigationView(container: container)
                        .environment(\.imageCache, imageCache)
                        .preferredColorScheme(.dark)
                        .onOpenURL { _ = DeepLinkHandler.shared.handle($0) }
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showSplash)
        }
    }
}
