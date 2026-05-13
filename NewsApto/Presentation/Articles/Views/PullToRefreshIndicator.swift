import SwiftUI

// MARK: - PullToRefreshIndicator

/// A custom pull-to-refresh indicator displayed at the top of the ScrollView.
/// Mimics the Apple News smooth spinner with a red accent.
struct PullToRefreshIndicator: View {
    let isRefreshing: Bool

    @State private var rotation: Double = 0

    var body: some View {
        HStack {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                    .frame(width: 24, height: 24)

                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(AppPalette.accent, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 24, height: 24)
                    .rotationEffect(.degrees(rotation))
                    .animation(
                        isRefreshing
                            ? .linear(duration: 0.7).repeatForever(autoreverses: false)
                            : .default,
                        value: rotation
                    )
            }
            .opacity(isRefreshing ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: isRefreshing)

            Spacer()
        }
        .frame(height: isRefreshing ? 50 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isRefreshing)
        .onAppear {
            if isRefreshing {
                rotation = 360
            }
        }
        .onChange(of: isRefreshing) { _, newValue in
            if newValue {
                rotation = 360
            } else {
                rotation = 0
            }
        }
    }
}

#if DEBUG
#if !CODEX_DISABLE_PREVIEWS
#Preview {
    VStack {
        PullToRefreshIndicator(isRefreshing: true)
        Spacer()
    }
}
#endif

#endif
