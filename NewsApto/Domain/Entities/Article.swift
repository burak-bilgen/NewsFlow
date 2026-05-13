import Foundation

struct Article: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    let sourceID: String
    let title: String
    let description: String?
    let imageURL: URL?
    let publishedAt: Date?
    let url: URL?
    var sourceName: String = ""
    var apiSource: APISource = .newsAPI
    var contentSnippet: String?

    init(
        id: String,
        sourceID: String,
        title: String,
        description: String? = nil,
        imageURL: URL? = nil,
        publishedAt: Date? = nil,
        url: URL? = nil,
        sourceName: String = "",
        apiSource: APISource = .newsAPI,
        contentSnippet: String? = nil
    ) {
        self.id = id
        self.sourceID = sourceID
        self.title = title
        self.description = description
        self.imageURL = imageURL
        self.publishedAt = publishedAt
        self.url = url
        self.sourceName = sourceName
        self.apiSource = apiSource
        self.contentSnippet = contentSnippet
    }

    var displayDate: String {
        ArticleDateFormatter.displayString(from: publishedAt)
    }
}

extension Article {
    enum CodingKeys: String, CodingKey {
        case id, sourceID, title, description, imageURL, publishedAt, url, sourceName, apiSource, contentSnippet
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        sourceID = try container.decode(String.self, forKey: .sourceID)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL)
        publishedAt = try container.decodeIfPresent(Date.self, forKey: .publishedAt)
        url = try container.decodeIfPresent(URL.self, forKey: .url)
        sourceName = try container.decodeIfPresent(String.self, forKey: .sourceName) ?? ""
        apiSource = try container.decodeIfPresent(APISource.self, forKey: .apiSource) ?? .newsAPI
        contentSnippet = try container.decodeIfPresent(String.self, forKey: .contentSnippet)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(sourceID, forKey: .sourceID)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encodeIfPresent(publishedAt, forKey: .publishedAt)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encode(sourceName, forKey: .sourceName)
        try container.encode(apiSource, forKey: .apiSource)
        try container.encodeIfPresent(contentSnippet, forKey: .contentSnippet)
    }
}

extension Article {
    var distinctContentSnippet: String? {
        guard let snippet = contentSnippet?.nilIfBlank else { return nil }

        let snippetKey = snippet.detailComparisonKey
        let duplicateKeys = [description, title].compactMap { $0?.nilIfBlank?.detailComparisonKey }

        return duplicateKeys.contains(snippetKey) ? nil : snippet
    }
}

private extension String {
    var detailComparisonKey: String {
        lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
