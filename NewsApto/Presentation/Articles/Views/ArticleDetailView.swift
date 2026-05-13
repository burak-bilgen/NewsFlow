import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    let sourceName: String
    var isSaved: Bool = false
    var onToggleReadingList: (() -> Void)?
    var heroNamespace: Namespace.ID? = nil

    @State private var showSafari = false
    @State private var showShareSheet = false

    var body: some View {
        ZStack {
            AppPalette.background.ignoresSafeArea()

            ScrollView {
                VStack {
                    VStack(alignment: .leading, spacing: 22) {
                        ArticleImageView(url: article.imageURL)
                            .frame(height: 280)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .clipped()
                            .cardStyle()

                        VStack(alignment: .leading, spacing: 12) {
                            metaRow

                            Text(article.title)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(AppPalette.textPrimary)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)

                            if let description = article.description, !description.isBlank {
                                Text(description)
                                    .font(.system(size: 17))
                                    .foregroundColor(AppPalette.textSecondary)
                                    .lineSpacing(5)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(18)
                        .cardStyle()

                        actionRow

                        if let snippet = article.contentSnippet, !snippet.isBlank {
                            Text(snippet)
                                .font(.system(size: 16))
                                .foregroundColor(AppPalette.textPrimary)
                                .lineSpacing(6)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(18)
                                .cardStyle()
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let onToggleReadingList {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onToggleReadingList()
                    } label: {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isSaved ? AppPalette.accent : AppPalette.textPrimary)
                            .frame(width: 36, height: 36)
                    }
                    .accessibilityLabel(isSaved ? L10n.text("readingList.remove") : L10n.text("readingList.add"))
                }
            }
        }
        .onAppear {
            ReadArticlesTracker.shared.markAsReadNonisolated(article.id)
        }
        .sheet(isPresented: $showSafari) {
            if let url = article.url {
                SafariView(url: url)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: shareItems)
        }
    }

    private var metaRow: some View {
        HStack(spacing: 8) {
            Text(displaySource.uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AppPalette.accent)

            Circle()
                .fill(AppPalette.textTertiary)
                .frame(width: 3, height: 3)

            Text(article.displayDate)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppPalette.textSecondary)

            if article.estimatedReadingMinutes > 0 {
                Circle()
                    .fill(AppPalette.textTertiary)
                    .frame(width: 3, height: 3)

                Text(article.readingTimeDisplay)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppPalette.textSecondary)
            }
        }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            if article.url != nil {
                Button {
                    showSafari = true
                } label: {
                    Label(L10n.text("article.readFull"), systemImage: "safari")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .foregroundColor(AppPalette.textPrimary)
                        .cardStyle()
                }
                .buttonStyle(.plain)
            }

            Button {
                showShareSheet = true
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppPalette.textPrimary)
                    .frame(width: 48, height: 48)
                    .cardStyle()
            }
            .buttonStyle(.plain)
        }
    }

    private var displaySource: String {
        sourceName.isBlank ? article.sourceID : sourceName
    }

    private var shareItems: [Any] {
        var items: [Any] = [article.title]
        if let url = article.url {
            items.append(url)
        }
        return items
    }
}
