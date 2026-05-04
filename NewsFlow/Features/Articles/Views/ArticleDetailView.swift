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
                    .frame(maxWidth: .infinity, minHeight: 300, idealHeight: 300, maxHeight: 300)
                    .clipShape(
                        RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    // Source badge + date
                    HStack {
                        Text(sourceName.uppercased())
                            .font(.system(size: 11, weight: .black))
                            .tracking(1.2)
                            .foregroundColor(.white)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, AppSpacing.xxs)
                            .background(
                                Capsule()
                                    .fill(AppPalette.primaryRed)
                            )

                        Spacer()

                        Text(article.displayDate)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(AppPalette.textSecondary)
                    }

                    // Title
                    Text(article.title)
                        .font(.system(size: 24, weight: .black, design: .serif))
                        .foregroundColor(AppPalette.textPrimary)
                        .lineSpacing(4)

                    Divider()
                        .padding(.vertical, AppSpacing.sm)

                    // Read more button
                    if let url = article.url {
                        Button {
                            showSafari = true
                        } label: {
                            HStack {
                                Image(systemName: "safari")
                                    .font(.system(size: 16, weight: .semibold))
                                Text(L10n.text("article.readFull"))
                                    .font(.subheadline.weight(.bold))
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.vertical, AppSpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                                    .fill(AppPalette.primaryRed)
                                    .shadow(color: AppPalette.primaryRed.opacity(0.3), radius: 12, x: 0, y: 6)
                            )
                        }
                        .buttonStyle(.plain)
                        .sheet(isPresented: $showSafari) {
                            SafariView(url: url)
                        }
                    }
                }
                .padding(AppSpacing.lg)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
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
