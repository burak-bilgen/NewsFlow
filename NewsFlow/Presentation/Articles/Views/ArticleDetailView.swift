import SwiftUI

/// Displays the full article with a large hero image and option to open
/// the original source in Safari.
struct ArticleDetailView: View {
    let article: Article
    let sourceName: String
    var isSaved: Bool = false
    var onToggleReadingList: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var showSafari = false
    @State private var appearAnimation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Hero image
                ZStack(alignment: .topTrailing) {
                    ArticleImageView(url: article.imageURL)
                        .frame(maxWidth: .infinity, minHeight: 320, idealHeight: 320, maxHeight: 320)
                        .clipShape(
                            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                        )
                        .overlay(
                            LinearGradient(
                                colors: [AppPalette.gradientStart, AppPalette.gradientMid, AppPalette.gradientEnd],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
                        )
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.top, AppSpacing.md)
                        .shadow(color: AppPalette.shadowColor.opacity(0.4), radius: 24, x: 0, y: 12)
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)
                        .animation(.easeOut(duration: 0.5), value: appearAnimation)
                    
                    if let onToggle = onToggleReadingList {
                        ReadingListToggleButton(
                            isSaved: isSaved,
                            displayStyle: .hero,
                            action: onToggle
                        )
                        .padding(AppSpacing.lg)
                    }
                }

                VStack(alignment: .leading, spacing: AppSpacing.lg) {

                    // Source badge + date
                    HStack(spacing: AppSpacing.sm) {
                        Text(sourceName.uppercased())
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, AppSpacing.xxs)
                            .background(
                                Capsule()
                                    .fill(AppPalette.primaryRed)
                                    .shadow(color: AppPalette.primaryRed.opacity(0.35), radius: 8, x: 0, y: 4)
                            )

                        Spacer()

                        Text(article.displayDate)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(AppPalette.textSecondary)
                    }

                    // Title with newspaper style
                    Text(article.title)
                        .font(.system(size: 28, weight: .black, design: .serif))
                        .foregroundColor(AppPalette.textPrimary)
                        .lineSpacing(6)

                    // Decorative divider
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(AppPalette.primaryRed)
                            .frame(width: 60, height: 3)
                        Rectangle()
                            .fill(AppPalette.textPrimary.opacity(0.15))
                            .frame(height: 1)
                    }

                    // Read more button
                    if let url = article.url {
                        Button {
                            showSafari = true
                        } label: {
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: "safari")
                                    .font(.system(size: 18, weight: .semibold))
                                Text(L10n.text("article.readFull"))
                                    .font(.subheadline.weight(.bold))
                                Spacer()
                                Image(systemName: "arrow.up.right.square.fill")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.vertical, AppSpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [AppPalette.primaryRed, AppPalette.primaryRedDark],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: AppPalette.primaryRed.opacity(0.35), radius: 16, x: 0, y: 8)
                            )
                        }
                        .buttonStyle(.plain)
                        .sheet(isPresented: $showSafari) {
                            SafariView(url: url)
                        }
                    }
                }
                .padding(AppSpacing.lg)
                .background(
                    AppPalette.elevatedBackground
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
                )
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.lg)
                .shadow(color: AppPalette.shadowColor.opacity(0.5), radius: 20, x: 0, y: 10)
                .opacity(appearAnimation ? 1 : 0)
                .offset(y: appearAnimation ? 0 : 30)
                .animation(.easeOut(duration: 0.6).delay(0.15), value: appearAnimation)
            }
            .padding(.bottom, AppSpacing.xl)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(AppPalette.textSecondary)
                }
            }
        }
        .onAppear {
            appearAnimation = true
        }
    }
}

#if DEBUG
#Preview {
    NavigationView {
        ArticleDetailView(
            article: NewsFixture.articlesBySource["bbc-news"]![0],
            sourceName: "BBC News"
        )
    }
}
#endif
