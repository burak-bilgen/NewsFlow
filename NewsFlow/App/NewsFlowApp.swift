import SwiftUI

@main
struct NewsFlowApp: App {
    @StateObject private var container = AppContainer.make()
    @StateObject private var themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            RootNavigationView(container: container)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.currentTheme.colorScheme)
        }
    }
}
