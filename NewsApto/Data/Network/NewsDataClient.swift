import Foundation

// MARK: - NewsData.io API Client
// Free tier: 200 requests/day
// 10,000+ news sources
// Docs: https://newsdata.io/docs

actor NewsDataClient {
    private let apiKey: String
    private let baseURL = URL(string: "https://newsdata.io/api/1")!
    private let session: URLSession
    private var nextPageToken: String?
    
    init(apiKey: String = APIConfig.newsdata.apiKey ?? "") {
        self.apiKey = apiKey
        self.session = URLSession.shared
    }
    
    func fetchLatestNews(
        country: String? = nil,
        category: String? = nil,
        page: String? = nil
    ) async throws -> NewsDataResult {
        var components = URLComponents(url: baseURL.appendingPathComponent("news"), resolvingAgainstBaseURL: false)!
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "apikey", value: apiKey),
            URLQueryItem(name: "language", value: "en")
        ]
        
        if let country = country {
            queryItems.append(URLQueryItem(name: "country", value: country))
        }
        
        if let category = category {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }
        
        if let page = page {
            queryItems.append(URLQueryItem(name: "page", value: page))
        }
        
        components.queryItems = queryItems
        
        let (data, response) = try await session.data(from: components.url!)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NewsAPIError.invalidResponse
        }
        
        let newsDataResponse = try JSONDecoder().decode(NewsDataResponse.self, from: data)
        
        return NewsDataResult(
            articles: newsDataResponse.results.map { $0.toArticle() },
            nextPage: newsDataResponse.nextPage
        )
    }
    
    struct NewsDataResult {
        let articles: [Article]
        let nextPage: String?
    }
}

// MARK: - DTOs

struct NewsDataResponse: Codable {
    let status: String
    let totalResults: Int
    let results: [NewsDataArticle]
    let nextPage: String?
}

struct NewsDataArticle: Codable {
    let articleId: String
    let title: String
    let link: String?
    let keywords: [String]?
    let creator: [String]?
    let videoUrl: String?
    let description: String?
    let content: String?
    let pubDate: String
    let imageUrl: String?
    let sourceId: String
    let sourceName: String
    let sourceUrl: String?
    let sourceIcon: String?
    let language: String
    let country: [String]?
    let category: [String]?
    
    func toArticle() -> Article {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let publishedDate = dateFormatter.date(from: pubDate)
        
        // Map first category from array
        let primaryCategory = category?.first?.lowercased()
        
        return Article(
            id: articleId,
            sourceID: sourceId,
            title: title,
            description: description,
            imageURL: imageUrl.flatMap { URL(string: $0) },
            publishedAt: publishedDate,
            url: link.flatMap { URL(string: $0) },
            sourceName: sourceName,
            apiSource: .newsdata,
            contentSnippet: content?.prefix(300).description,
            category: primaryCategory,
            badges: [],
            curationReason: nil
        )
    }
}
