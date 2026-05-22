import Foundation

// MARK: - HackerNews API Client
// Completely FREE - Firebase API
// Best for: Tech, Programming, Startups
// Docs: https://github.com/HackerNews/API

actor HackerNewsClient {
    private let baseURL: URL
    private let session: URLSession
    
    init() {
        self.baseURL = URL(string: "https://hacker-news.firebaseio.com/v0")!
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Fetch Methods
    
    func fetchTopStories(limit: Int = 30) async throws -> [Article] {
        let topIds = try await fetchTopStoryIds(limit: limit)
        return try await fetchStories(ids: topIds)
    }
    
    func fetchBestStories(limit: Int = 30) async throws -> [Article] {
        let bestIds = try await fetchBestStoryIds(limit: limit)
        return try await fetchStories(ids: bestIds)
    }
    
    func fetchNewStories(limit: Int = 30) async throws -> [Article] {
        let newIds = try await fetchNewStoryIds(limit: limit)
        return try await fetchStories(ids: newIds)
    }
    
    func fetchStories(ids: [Int]) async throws -> [Article] {
        try await withThrowingTaskGroup(of: Article?.self) { group in
            for id in ids {
                group.addTask {
                    try? await self.fetchStory(id: id)
                }
            }
            var articles: [Article] = []
            for try await article in group {
                if let article = article {
                    articles.append(article)
                }
            }
            return articles
        }
    }
    
    // MARK: - Private Methods
    
    private func fetchTopStoryIds(limit: Int) async throws -> [Int] {
        let url = baseURL.appendingPathComponent("topstories.json")
        let (data, _) = try await session.data(from: url)
        let allIds = try JSONDecoder().decode([Int].self, from: data)
        return Array(allIds.prefix(limit))
    }
    
    private func fetchBestStoryIds(limit: Int) async throws -> [Int] {
        let url = baseURL.appendingPathComponent("beststories.json")
        let (data, _) = try await session.data(from: url)
        let allIds = try JSONDecoder().decode([Int].self, from: data)
        return Array(allIds.prefix(limit))
    }
    
    private func fetchNewStoryIds(limit: Int) async throws -> [Int] {
        let url = baseURL.appendingPathComponent("newstories.json")
        let (data, _) = try await session.data(from: url)
        let allIds = try JSONDecoder().decode([Int].self, from: data)
        return Array(allIds.prefix(limit))
    }
    
    private func fetchStory(id: Int) async throws -> Article? {
        let url = baseURL.appendingPathComponent("item/\(id).json")
        let (data, _) = try await session.data(from: url)
        let story = try JSONDecoder().decode(HNStory.self, from: data)
        
        // Skip job postings and polls
        guard story.type == "story", let title = story.title else {
            return nil
        }
        
        let date = Date(timeIntervalSince1970: TimeInterval(story.time))
        
        // Use HN URL as fallback
        let storyUrl = story.url ?? "https://news.ycombinator.com/item?id=\(id)"
        
        // HN text only available for "self posts" - for link posts, create description from URL domain
        let description: String?
        if let text = story.text, !text.isEmpty {
            description = text.strippingHTML.prefix(200).description
        } else if let url = story.url, let urlObj = URL(string: url) {
            let host = urlObj.host?.replacingOccurrences(of: "www.", with: "") ?? "external site"
            description = "🔗 External link from \(host)"
        } else {
            description = nil
        }
        
        return Article(
            id: "hn-\(id)",
            sourceID: "hackernews",
            title: title,
            description: description,
            imageURL: nil, // HN doesn't provide images
            publishedAt: date,
            url: URL(string: storyUrl),
            sourceName: "Hacker News",
            apiSource: .hackernews,
            contentSnippet: story.text?.strippingHTML.prefix(2000).description ?? description,
            qualityScore: Double(story.score ?? 0),
            engagementScore: Double(story.score ?? 0)
        )
    }
}

// MARK: - DTOs

struct HNStory: Codable {
    let id: Int
    let type: String
    let by: String?
    let time: Int
    let text: String?
    let url: String?
    let score: Int?
    let title: String?
    let descendants: Int?
}

private extension String {
    var strippingHTML: String {
        self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}
