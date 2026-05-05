import SwiftUI
import Combine

// MARK: - State Restoration Manager

/// Manages app state restoration using NSUserActivity and SceneStorage.
/// Restores the last viewed screen and scroll position across app launches.
final class StateRestorationManager: ObservableObject {
    static let shared = StateRestorationManager()

    private let selectedSourceKey = "restoration.selectedSourceID"
    private let scrollOffsetKey = "restoration.scrollOffset"

    @Published var selectedSourceID: String? {
        didSet {
            UserDefaults.standard.set(selectedSourceID, forKey: selectedSourceKey)
        }
    }

    @Published var scrollOffset: CGFloat = 0 {
        didSet {
            UserDefaults.standard.set(scrollOffset, forKey: scrollOffsetKey)
        }
    }

    private init() {
        selectedSourceID = UserDefaults.standard.string(forKey: selectedSourceKey)
        scrollOffset = UserDefaults.standard.double(forKey: scrollOffsetKey)
    }

    func createUserActivity() -> NSUserActivity {
        let activity = NSUserActivity(activityType: "burakbilgen.NewsFlow.viewArticle")
        activity.title = "Reading Article"
        if let sourceID = selectedSourceID {
            activity.userInfo = ["sourceID": sourceID]
        }
        activity.isEligibleForHandoff = true
        return activity
    }

    func restore(from activity: NSUserActivity) {
        if let sourceID = activity.userInfo?["sourceID"] as? String {
            selectedSourceID = sourceID
        }
    }

    func clear() {
        selectedSourceID = nil
        scrollOffset = 0
        UserDefaults.standard.removeObject(forKey: selectedSourceKey)
        UserDefaults.standard.removeObject(forKey: scrollOffsetKey)
    }
}

// MARK: - View Extension

extension View {
    func withStateRestoration() -> some View {
        modifier(StateRestorationModifier())
    }
}

struct StateRestorationModifier: ViewModifier {
    @StateObject private var restorationManager = StateRestorationManager.shared

    func body(content: Content) -> some View {
        content
            .onAppear {
                restorationManager.selectedSourceID = UserDefaults.standard.string(
                    forKey: "restoration.selectedSourceID"
                )
            }
    }
}
