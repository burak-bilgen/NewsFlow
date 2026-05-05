import WidgetKit
import SwiftUI

// MARK: - Entry View

struct NewsFlowWidgetEntryView: View {
    var entry: NewsProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(article: entry.articles.first)
        case .systemMedium:
            MediumWidgetView(articles: Array(entry.articles.prefix(2)))
        case .systemLarge, .systemExtraLarge:
            LargeWidgetView(articles: entry.articles)
        case .accessoryCircular, .accessoryRectangular, .accessoryInline:
            LockScreenWidgetView(article: entry.articles.first)
        @unknown default:
            SmallWidgetView(article: entry.articles.first)
        }
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let article: ArticleWidgetModel?

    var body: some View {
        if let article = article {
            VStack(alignment: .leading, spacing: 4) {
                Text(article.sourceName)
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Text(article.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(3)
                Spacer()
            }
            .padding(12)
            .widgetURL(article.articleURL)
        } else {
            Text("No news available")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let articles: [ArticleWidgetModel]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(articles) { article in
                VStack(alignment: .leading, spacing: 4) {
                    Text(article.sourceName)
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.secondary)
                    Text(article.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(3)
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .widgetURL(article.articleURL)
            }
        }
        .padding(12)
    }
}

// MARK: - Large Widget

struct LargeWidgetView: View {
    let articles: [ArticleWidgetModel]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Top Headlines")
                .font(.headline.weight(.bold))
                .padding(.bottom, 4)

            ForEach(articles.prefix(5)) { article in
                Link(destination: article.articleURL ?? URL(string: "newsflow://")!) {
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentColor)
                            .frame(width: 4, height: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(article.sourceName)
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.secondary)
                            Text(article.title)
                                .font(.subheadline.weight(.medium))
                                .lineLimit(2)
                        }

                        Spacer()
                    }
                }
            }

            Spacer()
        }
        .padding(16)
    }
}

// MARK: - Lock Screen Widget

struct LockScreenWidgetView: View {
    let article: ArticleWidgetModel?

    var body: some View {
        if let article = article {
            HStack {
                Image(systemName: "newspaper")
                    .font(.title3)
                    .widgetAccentable()
                VStack(alignment: .leading, spacing: 2) {
                    Text(article.sourceName)
                        .font(.caption2.weight(.bold))
                    Text(article.title)
                        .font(.caption)
                        .lineLimit(1)
                }
            }
            .widgetURL(article.articleURL)
        } else {
            Text("NewsFlow")
                .font(.caption)
        }
    }
}
