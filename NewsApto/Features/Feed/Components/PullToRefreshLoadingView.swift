import SwiftUI

struct PullToRefreshLoadingView: View {
    @State private var cursorVisible = true
    @State private var lineOffset: CGFloat = 0
    @State private var rotation: Double = 0

    var body: some View {
        VStack(spacing: 16) {
            // Matrix-style code rain effect
            HStack(spacing: 6) {
                ForEach(0..<7) { index in
                    VStack(spacing: 3) {
                        ForEach(0..<3) { row in
                            Rectangle()
                                .fill(AppPalette.accent.opacity(0.2 + Double(index) * 0.1))
                                .frame(width: 4, height: 4)
                                .offset(y: lineOffset * (row == 1 ? 1 : -1))
                        }
                    }
                    .frame(width: 12)
                }
            }
            .frame(height: 30)
            .clipShape(Rectangle())

            // Rotating bracket indicator
            HStack(spacing: 12) {
                Text("[")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(AppPalette.accent)
                    .rotationEffect(.degrees(rotation))

                VStack(spacing: 4) {
                    Text("REFRESHING")
                        .font(AppTypography.monoSmall)
                        .foregroundColor(AppPalette.accent)

                    HStack(spacing: 2) {
                        Text("SYSTEM")
                            .font(AppTypography.monoTiny)
                            .foregroundColor(AppPalette.textSecondary)
                        Text("_")
                            .font(AppTypography.monoTiny.weight(.bold))
                            .foregroundColor(cursorVisible ? AppPalette.accent : .clear)
                    }
                }

                Text("]")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(AppPalette.accent)
                    .rotationEffect(.degrees(-rotation))
            }

            // Progress lines
            HStack(spacing: 4) {
                ForEach(0..<8) { index in
                    Rectangle()
                        .fill(AppPalette.accent.opacity(0.4 + (sin(Double(index)) + 1) * 0.3))
                        .frame(width: 20, height: 2)
                        .scaleEffect(y: cursorVisible ? 1 : 0.5)
                        .animation(.easeInOut(duration: 0.5).delay(Double(index) * 0.05), value: cursorVisible)
                }
            }
            .frame(width: 180)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 32)
        .background(
            ZStack {
                AppPalette.surface
                Rectangle()
                    .stroke(AppPalette.accent.opacity(0.3), lineWidth: 1)
            }
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                cursorVisible = false
            }
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                lineOffset = 10
            }
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

#if DEBUG
#if !CODEX_DISABLE_PREVIEWS
#Preview {
    ZStack {
        AppPalette.background.ignoresSafeArea()
        PullToRefreshLoadingView()
    }
}
#endif
#endif
