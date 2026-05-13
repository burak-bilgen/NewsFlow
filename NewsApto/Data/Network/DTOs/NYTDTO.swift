import Foundation

struct NYTSearchResponse: Decodable {
    let status: String?
    let response: NYTDocsResponse?
    let fault: NYTFault?
}

struct NYTFault: Decodable {
    let faultstring: String?
}

struct NYTDocsResponse: Decodable {
    let docs: [NYTArticleDTO]?
    let meta: NYTMeta?
}

struct NYTMeta: Decodable {
    let hits: Int?
    let offset: Int?
}

struct NYTArticleDTO: Decodable {
    let _id: String?
    let headline: NYTHeadline?
    let snippet: String?
    let pubDate: String?
    let webUrl: String?
    let multimedia: NYTMultimediaContainer?
    let source: String?
    let sectionName: String?

    enum CodingKeys: String, CodingKey {
        case _id
        case headline
        case snippet
        case pubDate = "pub_date"
        case webUrl = "web_url"
        case multimedia
        case source
        case sectionName = "section_name"
    }

    struct NYTHeadline: Decodable {
        let main: String?
    }

    struct NYTMultimediaContainer: Decodable {
        let caption: String?
        let credit: String?
        let defaultImage: NYTImageAsset?
        let thumbnail: NYTImageAsset?

        enum CodingKeys: String, CodingKey {
            case caption, credit
            case defaultImage = "default"
            case thumbnail
        }
    }

    struct NYTImageAsset: Decodable {
        let url: String?
        let width: Int?
        let height: Int?
    }

    var imageURL: URL? {
        if let url = multimedia?.defaultImage?.url ?? multimedia?.thumbnail?.url {
            return URL(string: url)
        }
        return nil
    }

    func domainModel() -> Article {
        let date = ArticleDateFormatter.parse(pubDate)
        let cleanSnippet = snippet?.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        return Article(
            id: "nyt-\(_id ?? UUID().uuidString)",
            sourceID: "nyt",
            title: headline?.main ?? L10n.text("article.title.untitled"),
            description: cleanSnippet,
            imageURL: imageURL,
            publishedAt: date,
            url: webUrl.flatMap(URL.init(string:)),
            sourceName: source ?? "The New York Times",
            apiSource: .nyt,
            contentSnippet: cleanSnippet
        )
    }
}
