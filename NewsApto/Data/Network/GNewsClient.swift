import Foundation


actor GNewsClient {
    private let apiKey: String
    private let baseURL: URL
    private let session: URLSession
    
    init(apiKey: String = APIConfig.gnews.apiKey ?? "") {
        self.baseURL = URL(string: "https://gnews.io/api/v4")!
        self.apiKey = apiKey
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        self.session = URLSession(configuration: config)
    }
    
    func fetchTopHeadlines(
        country: String = "us",
        max: Int = 20,
        page: Int = 1
    ) async throws -> [Article] {
        guard var components = URLComponents(url: baseURL.appendingPathComponent("top-headlines"), resolvingAgainstBaseURL: false) else {
            throw NewsAPIError.invalidURL
        }
        
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "token", value: apiKey),
            URLQueryItem(name: "max", value: String(max)),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "country", value: country),
            URLQueryItem(name: "lang", value: "en")
        ]
        
        components.queryItems = queryItems
        
        guard let requestURL = components.url else {
            throw NewsAPIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: requestURL)
        
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
        guard var components = URLComponents(url: baseURL.appendingPathComponent("search"), resolvingAgainstBaseURL: false) else {
            throw NewsAPIError.invalidURL
        }
        
        components.queryItems = [
            URLQueryItem(name: "token", value: apiKey),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "max", value: String(max)),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "lang", value: "en")
        ]
        
        guard let requestURL = components.url else {
            throw NewsAPIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: requestURL)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NewsAPIError.invalidResponse
        }
        
        let gnewsResponse = try JSONDecoder().decode(GNewsResponse.self, from: data)
        return gnewsResponse.articles.map { $0.toArticle() }
    }
}


struct GNewsResponse: Codable {
    let totalArticles: Int
    let articles: [GNewsArticle]
}

struct GNewsArticle: Codable {
    let title: String?
    let description: String?
    let content: String?
    let url: String?
    let image: String?
    let publishedAt: String?
    let source: GNewsSource?
    
    struct GNewsSource: Codable {
        let name: String?
        let url: String?
    }
    
    func toArticle() -> Article {
        let effectiveTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Untitled Article"
        let effectiveURL = url?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let effectiveSourceName = source?.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "GNews Source"
        
        let publishedDate = parseDate(publishedAt)
        
        let effectiveId = effectiveURL.isEmpty ? "gnews-\(abs(effectiveTitle.hashValue % 1_000_000))" : effectiveURL.md5Hash
        
        let imageURL: URL? = {
            guard let image = image else { return nil }
            let cleanUrl = image.trimmingCharacters(in: .whitespacesAndNewlines)
            return URL(string: cleanUrl)
        }()
        let articleURL: URL? = {
            guard !effectiveURL.isEmpty else { return nil }
            return URL(string: effectiveURL)
        }()
        
        return Article(
            id: effectiveId,
            sourceID: effectiveSourceName.lowercased().replacingOccurrences(of: " ", with: "-").replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression),
            title: effectiveTitle,
            description: description?.trimmingCharacters(in: .whitespacesAndNewlines),
            imageURL: imageURL,
            publishedAt: publishedDate,
            url: articleURL,
            sourceName: effectiveSourceName,
            apiSource: .gnews,
            contentSnippet: content.map { String($0.prefix(2000)) }
        )
    }
    
    private static let iso8601Formatter = ISO8601DateFormatter()
    private static let dateFormatters: [DateFormatter] = {
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd"
        ]
        return formats.map { format in
            let f = DateFormatter()
            f.dateFormat = format
            f.locale = Locale(identifier: "en_US_POSIX")
            f.timeZone = TimeZone(secondsFromGMT: 0)
            return f
        }
    }()

    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString?.trimmingCharacters(in: .whitespacesAndNewlines) else { return nil }
        if let date = Self.iso8601Formatter.date(from: dateString) { return date }
        for formatter in Self.dateFormatters {
            if let date = formatter.date(from: dateString) { return date }
        }
        return nil
    }
}

private extension String {
    var md5Hash: String {
        guard let data = self.data(using: .utf8) else {
            return String(self.prefix(16))
        }
        return data.base64EncodedString().prefix(16).description
    }
}
