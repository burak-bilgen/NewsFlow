import Foundation

struct ArticlesResponseDTO: NewsAPIResponseEnvelope {
    let status: String
    let totalResults: Int?
    let articles: [ArticleDTO]
    let code: String?
    let message: String?

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
            imageURL: imageURL,
            publishedAt: publishedDate,
            url: articleURL
        )
    }
}
