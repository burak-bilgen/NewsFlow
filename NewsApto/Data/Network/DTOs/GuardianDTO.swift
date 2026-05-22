import Foundation

struct GuardianSearchResponse: Decodable {
    let response: GuardianResponse
}

struct GuardianResponse: Decodable {
    let status: String
    let total: Int?
    let results: [GuardianArticleDTO]
}

struct GuardianArticleDTO: Decodable {
    let id: String
    let type: String?
    let sectionId: String?
    let sectionName: String?
    let webPublicationDate: String?
    let webTitle: String?
    let webUrl: String?
    let fields: GuardianFields?
    let blocks: GuardianBlocks?

    struct GuardianFields: Decodable {
        let trailText: String?
        let thumbnail: String?
        let bodyText: String?
    }

    struct GuardianBlocks: Decodable {
        let main: GuardianMainBlock?
    }

    struct GuardianMainBlock: Decodable {
        let elements: [GuardianBlockElement]?
    }

    struct GuardianBlockElement: Decodable {
        let type: String?
        let assets: [GuardianAsset]?
    }

    struct GuardianAsset: Decodable {
        let file: String?
        let typeData: GuardianTypeData?
    }

    struct GuardianTypeData: Decodable {
        let width: Int?
        let height: Int?
    }

    var articleURL: URL? { URL(string: webUrl ?? "") }

    var imageURL: URL? {
        if let thumbnail = fields?.thumbnail, let url = URL(string: thumbnail) {
            return url
        }
        if let assets = blocks?.main?.elements?.first?.assets, !assets.isEmpty {
            if assets.count > 1 {
                let sorted = assets.sorted { (Int($0.typeData?.width ?? 0) > Int($1.typeData?.width ?? 0)) }
                if let file = sorted.first?.file, let url = URL(string: file) { return url }
            } else if let file = assets.first?.file, let url = URL(string: file) {
                return url
            }
        }
        return nil
    }

    func domainModel() -> Article {
        let date = ArticleDateFormatter.parse(webPublicationDate)
        let snippet = fields?.trailText?.nilIfBlank ?? fields?.bodyText?.nilIfBlank
        let cleanSnippet = snippet?.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        return Article(
            id: "guardian-\(id)",
            sourceID: "guardian",
            title: webTitle ?? L10n.text("article.title.untitled"),
            description: cleanSnippet,
            imageURL: imageURL,
            publishedAt: date,
            url: articleURL,
            sourceName: "The Guardian",
            apiSource: .guardian,
            contentSnippet: cleanSnippet
        )
    }
}
