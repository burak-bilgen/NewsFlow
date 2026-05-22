import Foundation

struct ArticlesResponseDTO: NewsAPIResponseEnvelope {
    let status: String
    let totalResults: Int?
    let articles: [ArticleDTO]
    let code: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case status, totalResults, articles, code, message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decode(String.self, forKey: .status)
        totalResults = try container.decodeIfPresent(Int.self, forKey: .totalResults)
        articles = try container.decodeIfPresent([ArticleDTO].self, forKey: .articles) ?? []
        code = try container.decodeIfPresent(String.self, forKey: .code)
        message = try container.decodeIfPresent(String.self, forKey: .message)
    }

    init(
        status: String,
        totalResults: Int? = nil,
        articles: [ArticleDTO],
        code: String? = nil,
        message: String? = nil
    ) {
        self.status = status
        self.totalResults = totalResults
        self.articles = articles
        self.code = code
        self.message = message
    }
}

struct ArticleDTO: Decodable {
    struct Source: Decodable {
        let id: String?
        let name: String?
    }

    let source: Source?
    let title: String?
    let description: String?
    let content: String?
    let url: String?
    let urlToImage: String?
    let publishedAt: String?

    func domainModel(fallbackSourceID: String) -> Article? {
        let resolvedTitle = title?.nilIfBlank ?? L10n.text("article.title.untitled")
        let articleURL = url.flatMap(URL.init(string:))
        let imageURL = urlToImage.flatMap(URL.init(string:))
        let publishedDate = ArticleDateFormatter.parse(publishedAt)
        let stableID = articleURL?.absoluteString ?? "\(fallbackSourceID)-\(resolvedTitle)-\(publishedAt ?? "")"

        return Article(
            id: stableID,
            sourceID: source?.id?.nilIfBlank ?? fallbackSourceID,
            title: resolvedTitle,
            description: description?.nilIfBlank,
            imageURL: imageURL,
            publishedAt: publishedDate,
            url: articleURL,
            sourceName: source?.name?.nilIfBlank ?? "",
            contentSnippet: content?.nilIfBlank
        )
    }
}
