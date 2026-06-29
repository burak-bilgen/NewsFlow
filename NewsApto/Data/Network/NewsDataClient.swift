import Foundation


actor NewsDataClient {
    private let apiKey: String
    private let baseURL: URL
    private let session: URLSession
    private var nextPageToken: String?
    
    init(apiKey: String = APIConfig.newsdata.apiKey ?? "") {
        self.baseURL = URL(string: "https://newsdata.io/api/1")!
        self.apiKey = apiKey
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        self.session = URLSession(configuration: config)
    }
    
    func fetchLatestNews(
        country: String? = nil,
        category: String? = nil,
        page: String? = nil
    ) async throws -> NewsDataResult {
        guard var components = URLComponents(url: baseURL.appendingPathComponent("news"), resolvingAgainstBaseURL: false) else {
            throw NewsAPIError.invalidURL
        }
        
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
        
        let pageValue = page ?? nextPageToken
        if let pageValue {
            queryItems.append(URLQueryItem(name: "page", value: pageValue))
        }
        
        components.queryItems = queryItems
        
        guard let requestURL = components.url else {
            throw NewsAPIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: requestURL)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NewsAPIError.invalidResponse
        }
        
        let newsDataResponse = try JSONDecoder().decode(NewsDataResponse.self, from: data)
        nextPageToken = newsDataResponse.nextPage
        
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


struct NewsDataResponse: Codable {
    let status: String
    let totalResults: Int
    let results: [NewsDataArticle]
    let nextPage: String?
}

struct NewsDataArticle: Codable {
    let articleId: String?
    let title: String?  // Made optional with fallback
    let link: String?
    let keywords: [String]?
    let creator: [String]?
    let videoUrl: String?
    let description: String?
    let content: String?
    let pubDate: String?  // Made optional with fallback
    let imageUrl: String?
    let sourceId: String?
    let sourceName: String?  // Made optional with fallback
    let sourceUrl: String?
    let sourceIcon: String?
    let language: String?
    let country: [String]?
    let category: [String]?
    
    func toArticle() -> Article {
        let effectiveTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Untitled Article"
        
        let effectiveSourceName = sourceName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown Source"
        
        let publishedDate = parseDate(pubDate)
        
        let effectiveId = articleId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? generateFallbackId(title: effectiveTitle, source: effectiveSourceName, date: pubDate)
        
        let effectiveSourceID = sourceId?.trimmingCharacters(in: .whitespacesAndNewlines) 
            ?? effectiveSourceName.lowercased().replacingOccurrences(of: " ", with: "-").replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
        
        let articleURL: URL? = {
            guard let link = link else { return nil }
            let cleanUrl = link.trimmingCharacters(in: .whitespacesAndNewlines)
            return URL(string: cleanUrl)
        }()
        let imageURL: URL? = {
            guard let imageUrl = imageUrl else { return nil }
            let cleanUrl = imageUrl.trimmingCharacters(in: .whitespacesAndNewlines)
            return URL(string: cleanUrl)
        }()
        
        return Article(
            id: effectiveId,
            sourceID: effectiveSourceID,
            title: effectiveTitle,
            description: description?.trimmingCharacters(in: .whitespacesAndNewlines),
            imageURL: imageURL,
            publishedAt: publishedDate,
            url: articleURL,
            sourceName: effectiveSourceName,
            apiSource: .newsdata,
            contentSnippet: content.map { String($0.prefix(2000)) }
        )
    }
    
    private static let iso8601Formatter = ISO8601DateFormatter()
    private static let dateFormatters: [DateFormatter] = {
        let formats = [
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd",
            "dd-MM-yyyy HH:mm:ss",
            "yyyy/MM/dd HH:mm:ss"
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
        for formatter in Self.dateFormatters {
            if let date = formatter.date(from: dateString) { return date }
        }
        if let date = Self.iso8601Formatter.date(from: dateString) { return date }
        return nil
    }
    
    private func generateFallbackId(title: String, source: String, date: String?) -> String {
        let dateStr = date?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "nodate"
        let base = "\(title)_\(source)_\(dateStr)"
        let hash = abs(base.hashValue % 1_000_000)
        return "newsdata-\(String(hash))"
    }
}
