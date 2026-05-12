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
    let leadParagraph: String?
    let pubDate: String?
    let webUrl: String?
    let multimedia: [NYTMultimedia]?
    let source: String?
    let sectionName: String?

    enum CodingKeys: String, CodingKey {
        case _id
        case headline
        case snippet
        case leadParagraph = "lead_paragraph"
        case pubDate = "pub_date"
        case webUrl = "web_url"
        case multimedia
        case source
        case sectionName = "section_name"
    }

    struct NYTHeadline: Decodable {
        let main: String?
    }

    struct NYTMultimedia: Decodable {
        let url: String?
        let subtype: String?
        let width: Int?
        let height: Int?
    }

    var imageURL: URL? {
        guard let multimedia, !multimedia.isEmpty else { return nil }
        let image = multimedia.first { $0.subtype == "superJumbo" }
            ?? multimedia.first { $0.subtype == "master495" }
            ?? multimedia.first
        guard let path = image?.url else { return nil }
        return URL(string: "https://www.nytimes.com/\(path)")
    }

    func domainModel() -> Article {
        let date = ArticleDateFormatter.parse(pubDate)
        let snippetText = snippet?.nilIfBlank ?? leadParagraph?.nilIfBlank
        let cleanSnippet = snippetText?.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

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
