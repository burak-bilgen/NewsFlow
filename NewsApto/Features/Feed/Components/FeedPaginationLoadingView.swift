import SwiftUI

struct FeedPaginationLoadingView: View {
    @State private var cursorVisible = true
    @State private var dotCount = 0
    @State private var lineOffset: CGFloat = 0
    @State private var timer: Timer?

    private var dots: String {
        String(repeating: ".", count: dotCount % 4)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                ForEach(0..<5) { index in
                    Rectangle()
                        .fill(AppPalette.accent.opacity(0.3 + Double(index) * 0.15))
                        .frame(width: 20 + CGFloat(index) * 8, height: 2)
                        .offset(y: lineOffset)
                        .animation(
                            .easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.1),
                            value: lineOffset
                        )
                }
            }
            .frame(height: 20)
            .clipShape(Rectangle())

            HStack(spacing: 6) {
                Text("\(L10n.text("loading.more"))\(dots)")
                    .font(AppTypography.monoSmall)
                    .foregroundColor(AppPalette.accent)

                Text("_")
                    .font(AppTypography.monoSmall.weight(.bold))
                    .foregroundColor(cursorVisible ? AppPalette.accent : .clear)
            }

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(AppPalette.surfaceElevated)
                    .frame(height: 2)

                Rectangle()
                    .fill(AppPalette.accent)
                    .frame(width: 60 + CGFloat(dotCount % 3) * 40, height: 2)
                    .animation(.easeInOut(duration: 0.4), value: dotCount)
            }
            .frame(width: 180)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
        .background(
            Rectangle()
                .fill(AppPalette.surface)
                .overlay(
                    Rectangle()
                        .stroke(AppPalette.accent.opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                cursorVisible = false
            }
            let t = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] _ in
                self?.dotCount += 1
            }
            timer = t
            RunLoop.current.add(t, forMode: .common)
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: true)) {
                lineOffset = 8
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
}

#if DEBUG
#if !CODEX_DISABLE_PREVIEWS
#Preview {
    ZStack {
        AppPalette.background.ignoresSafeArea()
        VStack {
            Spacer()
            FeedPaginationLoadingView()
            Spacer()
        }
    }
}
#endif
#endif
