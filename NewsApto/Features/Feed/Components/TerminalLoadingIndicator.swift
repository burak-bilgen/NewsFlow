import SwiftUI

struct TerminalLoadingIndicator: View {
    @State private var cursorVisible = true
    @State private var dotCount = 0

    private var dots: String {
        String(repeating: ".", count: dotCount % 4)
    }

    var body: some View {
        HStack(spacing: 6) {
            Text("> LOADING\(dots)")
                .font(AppTypography.monoSmall)
                .foregroundColor(AppPalette.accent)

            Text("_")
                .font(AppTypography.monoSmall.weight(.bold))
                .foregroundColor(cursorVisible ? AppPalette.accent : .clear)
        }
        .onAppear {
            withAnimation(AppAnimation.blink) { cursorVisible = false }
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                dotCount += 1
            }
        }
    }
}

#if DEBUG
#if !CODEX_DISABLE_PREVIEWS
#Preview {
    ZStack {
        AppPalette.background.ignoresSafeArea()
        TerminalLoadingIndicator()
    }
}
#endif
#endif
