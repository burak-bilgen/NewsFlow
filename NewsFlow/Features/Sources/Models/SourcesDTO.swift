import Foundation

struct SourcesResponseDTO: NewsAPIResponseEnvelope {
    let status: String
    let sources: [SourceDTO]
    let code: String?
    let message: String?

    init(status: String, sources: [SourceDTO], code: String? = nil, message: String? = nil) {
        self.status = status
        self.sources = sources
        self.code = code
        self.message = message
    }
}

struct SourceDTO: Decodable {
    let id: String?
    let name: String?
    let description: String?
    let url: String?
    let category: String?
    let language: String?

    func domainModel() -> NewsSource? {
        guard let id, !id.isEmpty else { return nil }
        return NewsSource(
            id: id,
            name: name?.nilIfBlank ?? id,
            description: description?.nilIfBlank ?? L10n.text("source.description.missing"),
            category: category?.nilIfBlank ?? "general",
            language: language?.nilIfBlank ?? "",
            url: url?.nilIfBlank
        )
    }
}
