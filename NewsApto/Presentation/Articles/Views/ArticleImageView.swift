import SwiftUI

struct ArticleImageView: View {
    let url: URL?
    @Environment(\.imageCache) private var imageCache
    @State private var uiImage: UIImage?
    @State private var didFail = false
    @State private var isLoading = false

    var body: some View {
        ZStack {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .clipped()
            } else if didFail || url == nil {
                placeholder
            } else if isLoading {
                loadingPlaceholder
            } else {
                placeholder
            }
        }
        .clipped()
        .task(id: url) { await loadImage() }
    }

    private func loadImage() async {
        guard let url else { return }
        didFail = false; isLoading = true
        if let loaded = await imageCache.loadImage(from: url) {
            isLoading = false; uiImage = loaded
        } else {
            isLoading = false; didFail = true
        }
    }

    private var loadingPlaceholder: some View {
        ZStack {
            // Matrix digital rain background
            AppPalette.surface
            
            // Scan line effect
            VStack(spacing: 0) {
                ForEach(0..<8) { i in
                    Rectangle()
                        .fill(AppPalette.accent.opacity(0.05 + Double(i % 3) * 0.02))
                        .frame(height: 4)
                }
            }
            
            // Central loading indicator
            VStack(spacing: 8) {
                // Animated matrix bracket
                HStack(spacing: 4) {
                    Text("[")
                        .font(AppTypography.monoSmall.weight(.bold))
                        .foregroundColor(AppPalette.accent)
                    
                    // Blinking cursor effect
                    Rectangle()
                        .fill(AppPalette.accent)
                        .frame(width: 8, height: 16)
                        .opacity(loadingBlink ? 1 : 0.3)
                        .animation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true), value: loadingBlink)
                        .onAppear { loadingBlink = true }
                    
                    Text("]")
                        .font(AppTypography.monoSmall.weight(.bold))
                        .foregroundColor(AppPalette.accent)
                }
                
                Text(L10n.text("loading.image"))
                    .font(AppTypography.monoTiny)
                    .foregroundColor(AppPalette.accent.opacity(0.7))
            }
        }
    }
    
    @State private var loadingBlink = false

    private var placeholder: some View {
        ZStack {
            // Matrix-themed background
            AppPalette.surface
            
            // Digital rain matrix pattern
            MatrixRainPattern()
            
            // Gradient overlay for depth
            LinearGradient(
                colors: [
                    AppPalette.accent.opacity(0.05),
                    .clear,
                    AppPalette.accent.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Matrix frame corners
            VStack {
                HStack {
                    MatrixCorner(position: .topLeft)
                    Spacer()
                    MatrixCorner(position: .topRight)
                }
                Spacer()
                HStack {
                    MatrixCorner(position: .bottomLeft)
                    Spacer()
                    MatrixCorner(position: .bottomRight)
                }
            }
            .padding(12)
            
            // Center icon with matrix styling
            VStack(spacing: 8) {
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(AppPalette.accent.opacity(0.1))
                        .frame(width: 56, height: 56)
                        .blur(radius: 8)
                    
                    Image(systemName: "newspaper.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppPalette.accent, AppPalette.accent.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                Text(L10n.text("placeholder.no_image"))
                    .font(AppTypography.monoTiny)
                    .foregroundColor(AppPalette.accent.opacity(0.5))
            }
        }
    }
}

// MARK: - Matrix Pattern Views

private struct MatrixRainPattern: View {
    var body: some View {
        Canvas { context, size in
            let columns = Int(size.width / 12)
            let rows = Int(size.height / 16)
            
            for col in 0..<columns {
                for row in 0..<rows {
                    let x = CGFloat(col) * 12 + 6
                    let y = CGFloat(row) * 16 + 8
                    
                    // Random opacity for matrix effect
                    let opacity = Double.random(in: 0.02...0.15)
                    
                    // Draw small matrix characters
                    let chars = ["0", "1", "│", "║", "▌", "▐"]
                    let char = chars.randomElement()!
                    
                    let text = Text(char)
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundColor(AppPalette.accent.opacity(opacity))
                    
                    context.draw(text, at: CGPoint(x: x, y: y))
                }
            }
        }
        .opacity(0.6)
    }
}

private struct MatrixCorner: View {
    enum Position {
        case topLeft, topRight, bottomLeft, bottomRight
    }
    
    let position: Position
    
    var body: some View {
        ZStack {
            // Corner bracket lines
            HStack(spacing: 0) {
                if position == .topLeft || position == .bottomLeft {
                    horizontalLine
                    verticalLine
                } else {
                    verticalLine
                    horizontalLine
                }
            }
        }
        .frame(width: 16, height: 16)
    }
    
    private var horizontalLine: some View {
        Rectangle()
            .fill(AppPalette.accent.opacity(0.4))
            .frame(width: 12, height: 2)
    }
    
    private var verticalLine: some View {
        Rectangle()
            .fill(AppPalette.accent.opacity(0.4))
            .frame(width: 2, height: 12)
    }
}
