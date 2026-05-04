import SafariServices
import SwiftUI

// MARK: - SafariView

/// Wraps SFSafariViewController for SwiftUI presentation.
/// Opens the article's original URL in an in-app browser.
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.preferredControlTintColor = UIColor(AppPalette.primaryRed)
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - ArticleDetailView

/// Displays the full article with a large hero image and option to open
/// the original source in Safari.
struct ArticleDetailView: View {
    let article: Article
    let sourceName: String
    @Environment(\.dismiss) private var dismiss
    @State private var showSafari = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Hero image
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

                VStack(alignment: .leading, spacing: AppSpacing.lg) {

                    // Source badge + date
                    HStack(spacing: AppSpacing.sm) {
                        Text(sourceName.uppercased())
                            .font(.system(size: 11, weight: .black))
                            .tracking(1.2)
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

                    // Title
                    Text(article.title)
                        .font(.system(size: 28, weight: .black, design: .serif))
                        .foregroundColor(AppPalette.textPrimary)
                        .lineSpacing(6)

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
