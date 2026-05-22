import SwiftUI
import UserNotifications

@main
struct NewsAptoApp: App {
    @StateObject private var container = AppContainer.make()
    private let imageCache: ImageCacheServicing = ImageCacheAdapter()
    @State private var showSplash = true
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    init() {
        requestNotificationPermission()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView { showSplash = false }.transition(.opacity)
                } else if !hasCompletedOnboarding {
                    OnboardingView { hasCompletedOnboarding = true }
                        .transition(.opacity)
                } else {
                    RootNavigationView(container: container)
                        .environment(\.imageCache, imageCache)
                        .preferredColorScheme(.dark)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showSplash)
            .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
        }
    }

    private func requestNotificationPermission() {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            if settings.authorizationStatus == .notDetermined {
                _ = try? await center.requestAuthorization(options: [.alert, .sound])
            }
        }
    }
}
