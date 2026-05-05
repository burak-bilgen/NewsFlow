import Network
import Combine
import SwiftUI

// MARK: - Network Monitor

/// Monitors network connectivity and publishes status changes.
/// Uses NWPathMonitor for accurate reachability detection including VPN and captive portals.
@MainActor
final class NetworkMonitor: ObservableObject {
    enum Status: Equatable {
        case connected
        case disconnected
        case expensive // cellular, metered WiFi

        var isConnected: Bool {
            self == .connected || self == .expensive
        }
    }

    @Published private(set) var status: Status = .connected

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "newsflow.networkmonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.updateStatus(from: path)
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    private func updateStatus(from path: NWPath) {
        switch path.status {
        case .satisfied:
            status = path.isExpensive ? .expensive : .connected
        case .unsatisfied, .requiresConnection:
            status = .disconnected
        @unknown default:
            status = .disconnected
        }
    }
}

// MARK: - Offline Banner View

struct OfflineBannerView: View {
    let isOffline: Bool

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 14, weight: .semibold))
            Text("No internet connection")
                .font(.caption.weight(.semibold))
            Spacer()
        }
        .foregroundColor(.white)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.xs)
        .background(AppPalette.primaryInk)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - View Modifier

struct OfflineAwareModifier: ViewModifier {
    @StateObject private var monitor = NetworkMonitor()

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content

            if !monitor.status.isConnected {
                OfflineBannerView(isOffline: true)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: monitor.status)
    }
}

extension View {
    func offlineAware() -> some View {
        modifier(OfflineAwareModifier())
    }
}
