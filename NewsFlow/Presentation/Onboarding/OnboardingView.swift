import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var appearAnimation = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "newspaper.fill",
            title: "Your AI-Powered News Feed",
            description: "All your news from top sources, intelligently sorted by importance and relevance — so you never miss what matters.",
            color: AppPalette.brandPrimary
        ),
        OnboardingPage(
            icon: "sparkle.magnifyingglass",
            title: "Smart Summaries",
            description: "Get AI-generated article summaries on supported devices. Tap 'Summarize' to get the key points in seconds.",
            color: AppPalette.accent
        ),
        OnboardingPage(
            icon: "ear.fill",
            title: "Listen on the Go",
            description: "Can't read now? Tap 'Listen' and let your articles be read aloud. Perfect for commutes and workouts.",
            color: AppPalette.success
        ),
        OnboardingPage(
            icon: "bookmark.fill",
            title: "Read Anywhere, Anytime",
            description: "Save articles to your reading list, share beautiful cards with friends, and pick up right where you left off.",
            color: AppPalette.brandPrimaryLight
        ),
        OnboardingPage(
            icon: "square.grid.2x2",
            title: "Browse by Source",
            description: "Prefer a specific source? Browse articles from BBC, The Guardian, NYT, and more — all in one place.",
            color: AppPalette.accent
        )
    ]

    var body: some View {
        ZStack {
            AppPalette.screenBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page, isActive: currentPage == index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)

                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? AppPalette.brandPrimary : AppPalette.border)
                            .frame(width: currentPage == index ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.bottom, AppSpacing.lg)

                // Buttons
                VStack(spacing: AppSpacing.sm) {
                    if currentPage == pages.count - 1 {
                        Button {
                            Haptic.success()
                            withAnimation {
                                hasSeenOnboarding = true
                            }
                        } label: {
                            Text("Get Started")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(AppPalette.brandPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    } else {
                        Button {
                            Haptic.light()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentPage += 1
                            }
                        } label: {
                            Text("Continue")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(AppPalette.brandPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }

                    Button {
                        withAnimation { hasSeenOnboarding = true }
                    } label: {
                        Text("Skip")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppPalette.textTertiary)
                    }
                    .opacity(currentPage < pages.count - 1 ? 1 : 0)
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.bottom, AppSpacing.xxl)
                .animation(.easeInOut, value: currentPage)
            }
        }
        .onAppear { appearAnimation = true }
    }
}

private struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

private struct OnboardingPageView: View {
    let page: OnboardingPage
    let isActive: Bool
    @State private var appears = false

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.12))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)

                Circle()
                    .fill(page.color.opacity(0.2))
                    .frame(width: 90, height: 90)

                Image(systemName: page.icon)
                    .font(.system(size: 40))
                    .foregroundColor(page.color)
                    .modifier(SymbolBounceModifier(isActive: isActive))
            }
            .scaleEffect(appears ? 1 : 0.6)
            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: appears)

            Text(page.title)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(AppPalette.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)

            Text(page.description)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(AppPalette.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, AppSpacing.xxl)
        }
        .padding(.vertical, AppSpacing.xl)
        .opacity(appears ? 1 : 0)
        .offset(y: appears ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.2), value: appears)
        .onAppear { appears = true }
        .onDisappear { appears = false }
    }
}

#if DEBUG
#Preview {
    OnboardingView()
}
#endif

private struct SymbolBounceModifier: ViewModifier {
    let isActive: Bool
    @State private var bounce = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(bounce ? 1.1 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6).repeatCount(1), value: bounce)
            .onChange(of: isActive) { newValue in
                if newValue { bounce = true }
            }
    }
}
