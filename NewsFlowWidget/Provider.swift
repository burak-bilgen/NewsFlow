import WidgetKit
import SwiftUI

// MARK: - Widget Model

/// Lightweight model for widget display, decoupled from the main app target.
struct ArticleWidgetModel: Identifiable {
    let id: String
    let title: String
    let sourceName: String
    let imageURL: URL?
    let articleURL: URL?
}

// MARK: - Timeline Entry

struct NewsEntry: TimelineEntry {
    let date: Date
    let articles: [ArticleWidgetModel]
}

// MARK: - Provider

struct NewsProvider: TimelineProvider {
    private let apiKey: String

    init() {
        // Widget shares the same Info.plist or reads from shared App Group
        // For simplicity, falls back to empty key if not configured
        self.apiKey = Bundle.main.object(forInfoDictionaryKey: "NewsAPIKey") as? String ?? ""
    }

    func placeholder(in context: Context) -> NewsEntry {
        NewsEntry(date: Date(), articles: placeholderArticles)
    }

    func getSnapshot(in context: Context, completion: @escaping (NewsEntry) -> Void) {
        let entry = NewsEntry(date: Date(), articles: placeholderArticles)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NewsEntry>) -> Void) {
        Task {
            let articles = await fetchTopHeadlines()
            let entry = NewsEntry(date: Date(), articles: articles)
            // Refresh every 15 minutes
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }

    // MARK: - Private

    private var placeholderArticles: [ArticleWidgetModel] {
        [
            ArticleWidgetModel(
                id: "1",
                title: "Breaking News: SwiftUI Widgets Are Awesome",
                sourceName: "Tech Daily",
                imageURL: nil,
                articleURL: nil
            ),
            ArticleWidgetModel(
                id: "2",
                title: "Apple Announces New Developer Tools",
                sourceName: "AppleInsider",
                imageURL: nil,
                articleURL: nil
            )
        ]
    }

    private func fetchTopHeadlines() async -> [ArticleWidgetModel] {
        guard !apiKey.isEmpty else { return placeholderArticles }

        let urlString = "https://newsapi.org/v2/top-headlines?country=us&pageSize=5&apiKey=\(apiKey)"
        guard let url = URL(string: urlString) else { return placeholderArticles }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return placeholderArticles
            }

            let decoded = try JSONDecoder().decode(WidgetArticlesResponse.self, from: data)
            return decoded.articles.compactMap { article in
                guard let title = article.title, title != "[Removed]" else { return nil }
                return ArticleWidgetModel(
                    id: article.url ?? UUID().uuidString,
                    title: title,
                    sourceName: article.source?.name ?? "News",
                    imageURL: article.urlToImage.flatMap { URL(string: $0) },
                    articleURL: article.url.flatMap { URL(string: $0) }
                )
            }
        } catch {
            return placeholderArticles
        }
    }
}

// MARK: - DTOs

private struct WidgetArticlesResponse: Decodable {
    let articles: [WidgetArticleDTO]
}

private struct WidgetArticleDTO: Decodable {
    let source: WidgetSourceDTO?
    let title: String?
    let url: String?
    let urlToImage: String?
}

private struct WidgetSourceDTO: Decodable {
    let name: String?
}
