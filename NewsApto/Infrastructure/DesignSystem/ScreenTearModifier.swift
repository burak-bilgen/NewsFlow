import SwiftUI

struct ScreenTearModifier: ViewModifier {
    @State private var tearOffset: CGFloat = 0
    @State private var tearOpacity: Double = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(AppPalette.accent.opacity(tearOpacity))
                    .frame(height: 1)
                    .offset(y: tearOffset)
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        tearOffset = CGFloat.random(in: -50...50)
                        tearOpacity = 0.3
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(50))
                            withAnimation(AppAnimation.press) {
                                tearOpacity = 0
                                tearOffset = 0
                            }
                        }
                    }
            )
    }
}

extension View {
    func screenTear() -> some View {
        modifier(ScreenTearModifier())
    }
}
