import SwiftUI

struct MatrixCodeRainView: View {
    @State private var isVisible = false
    @State private var scale: CGFloat = 0.7

    let columns = 24
    let rows = 40
    let chars = "アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン0123456789ABCDEF".map { $0 }

    var body: some View {
        ZStack {
            AppPalette.background.ignoresSafeArea()

            TimelineView(.animation(minimumInterval: 0.05)) { timeline in
                Canvas { context, size in
                    let colW = size.width / CGFloat(columns)
                    let rowH = size.height / CGFloat(rows)
                    let t = Int(timeline.date.timeIntervalSinceReferenceDate * 25)

                    for col in 0..<columns {
                        let seed = col * 17
                        let dropOffset = (seed + t / 2) % (rows + 8)

                        for row in 0..<rows {
                            let y = CGFloat(row) * rowH
                            let ci = (col * 31 + row * 31 + t) % chars.count
                            let distFromHead = (row - dropOffset + rows * 2) % rows

                            let alpha: Double = {
                                if distFromHead == 0 { return 0.95 }
                                if distFromHead < 2 { return 0.7 }
                                if distFromHead < 5 { return 0.4 }
                                if distFromHead < 10 { return 0.15 }
                                return 0.04
                            }()

                            let isHead = distFromHead == 0
                            context.opacity = alpha * isVisible.doubleValue
                            context.draw(
                                Text(String(chars[ci]))
                                    .font(.system(size: colW * 0.7, weight: isHead ? .bold : .regular, design: .monospaced))
                                    .foregroundColor(isHead ? .white : AppPalette.accent),
                                at: CGPoint(x: CGFloat(col) * colW + colW / 2, y: y)
                            )
                        }
                    }
                }
            }
            .scaleEffect(scale)
            .opacity(isVisible ? 1 : 0)
        }
        .onAppear {
            withAnimation(AppAnimation.transition) { scale = 1.0 }
            withAnimation(AppAnimation.reveal) { isVisible = true }
        }
    }
}

private extension Bool {
    var doubleValue: Double { self ? 1 : 0 }
}
