import Foundation

// MARK: - GNews API Client
// Free tier: 100 requests/day
// Docs: https://gnews.io/docs

actor GNewsClient {
    private let apiKey: String
    private let baseURL = URL(string: "https://gnews.io/api/v4")!
    private let session: URLSession
    
    init(apiKey: String = APIConfig.gnews.apiKey ?? "") {
        self.apiKey = apiKey
        self.session = URLSession.shared
    }
    
    func fetchTopHeadlines(
        country: String = "us",
        max: Int = 20,
        page: Int = 1
    ) async throws -> [Article] {
        var components = URLComponents(url: baseURL.appendingPathComponent("top-headlines"), resolvingAgainstBaseURL: false)!
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "token", value: apiKey),
            URLQueryItem(name: "max", value: String(max)),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "country", value: country),
            URLQueryItem(name: "lang", value: "en")
        ]
        
        components.queryItems = queryItems
        
        let (data, response) = try await session.data(from: components.url!)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NewsAPIError.invalidResponse
        }
        
        let gnewsResponse = try JSONDecoder().decode(GNewsResponse.self, from: data)
        return gnewsResponse.articles.map { $0.toArticle() }
    }
    
    func searchNews(
        query: String,
        max: Int = 20,
        page: Int = 1
    ) async throws -> [Article] {
        var components = URLComponents(url: baseURL.appendingPathComponent("search"), resolvingAgainstBaseURL: false)!
        
        components.queryItems = [
            URLQueryItem(name: "token", value: apiKey),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "max", value: String(max)),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "lang", value: "en")
        ]
        
        let (data, response) = try await session.data(from: components.url!)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NewsAPIError.invalidResponse
        }
        
        let gnewsResponse = try JSONDecoder().decode(GNewsResponse.self, from: data)
        return gnewsResponse.articles.map { $0.toArticle() }
    }
}

// MARK: - DTOs

struct GNewsResponse: Codable {
    let totalArticles: Int
    let articles: [GNewsArticle]
}

struct GNewsArticle: Codable {
    let title: String
    let description: String?
    let content: String?
    let url: String
    let image: String?
    let publishedAt: String
    let source: GNewsSource
    
    struct GNewsSource: Codable {
        let name: String
        let url: String?
    }
    
    func toArticle() -> Article {
        let dateFormatter = ISO8601DateFormatter()
        let publishedDate = dateFormatter.date(from: publishedAt)
        
        return Article(
            id: url.md5Hash,
            sourceID: source.name.lowercased().replacingOccurrences(of: " ", with: "-"),
            title: title,
            description: description,
            imageURL: image.flatMap { URL(string: $0) },
            publishedAt: publishedDate,
            url: URL(string: url),
            sourceName: source.name,
            apiSource: .gnews,
            contentSnippet: content?.prefix(2000).description
        )
    }
}

private extension String {
    var md5Hash: String {
        // Simple hash for demo - use CryptoKit in production
        return self.data(using: .utf8)!.base64EncodedString().prefix(16).description
    }
}
