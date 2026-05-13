import SwiftUI

struct SplashView: View {
    @State private var scale: CGFloat = 0.6
    @State private var opacity: CGFloat = 0
    @State private var textOpacity: CGFloat = 0
    @State private var taglineOpacity: CGFloat = 0
    @State private var isComplete = false

    let onComplete: () -> Void

    var body: some View {
        ZStack {
            AppPalette.background.ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer()

                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .scaleEffect(scale)
                    .opacity(opacity)

                Text("NewsApto")
                    .font(.system(size: 32, weight: .black, design: .serif))
                    .foregroundColor(AppPalette.textPrimary)
                    .opacity(textOpacity)

                Text("Smart. Adaptive. Personal.")
                    .font(.system(size: 14, weight: .regular, design: .serif))
                    .foregroundColor(AppPalette.accent)
                    .opacity(taglineOpacity)

                Spacer()

                Text("Powered by NewsAPI, The Guardian & NYT")
                    .font(.system(size: 10))
                    .foregroundColor(AppPalette.textTertiary)
                    .opacity(taglineOpacity)
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
                textOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                taglineOpacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.easeIn(duration: 0.2)) {
                    isComplete = true
                }
                onComplete()
            }
        }
    }
}
