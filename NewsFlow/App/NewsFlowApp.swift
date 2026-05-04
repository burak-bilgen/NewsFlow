import SwiftUI

@main
struct NewsFlowApp: App {
    @StateObject private var container = AppContainer.make()

    var body: some Scene {
        WindowGroup {
            RootNavigationView(container: container)
        }
    }
}
