import CoreSpotlight
import MobileCoreServices
import UniformTypeIdentifiers

// MARK: - Spotlight Indexing Use Case

/// Indexes articles into Core Spotlight so users can find them via iOS system search.
/// Uses CSSearchableIndex with batched updates for performance.
protocol SpotlightIndexing {
    func index(articles: [Article]) async
    func deindex(articleIDs: [String]) async
    func deindexAll() async
}

final class IndexArticlesInSpotlightUseCase: SpotlightIndexing {
    private let searchableIndex: CSSearchableIndex

    init(searchableIndex: CSSearchableIndex = .default()) {
        self.searchableIndex = searchableIndex
    }

    func index(articles: [Article]) async {
        let items = articles.map { article -> CSSearchableItem in
            let attributeSet = CSSearchableItemAttributeSet(itemContentType: UTType.text.identifier)
            attributeSet.title = article.title
            attributeSet.contentDescription = article.displayDate
            attributeSet.displayName = article.title
            attributeSet.keywords = [article.sourceID]
            if let url = article.url {
                attributeSet.relatedUniqueIdentifier = url.absoluteString
            }

            let item = CSSearchableItem(
                uniqueIdentifier: article.id,
                domainIdentifier: "burakbilgen.NewsFlow.article",
                attributeSet: attributeSet
            )
            return item
        }

        do {
            try await searchableIndex.indexSearchableItems(items)
            NewsFlowLogger.shared.info("Indexed \(items.count) articles in Spotlight", category: "Spotlight")
        } catch {
            NewsFlowLogger.shared.error("Failed to index articles: \(error.localizedDescription)", category: "Spotlight")
        }
    }

    func deindex(articleIDs: [String]) async {
        do {
            try await searchableIndex.deleteSearchableItems(withIdentifiers: articleIDs)
            NewsFlowLogger.shared.info("Deindexed \(articleIDs.count) articles from Spotlight", category: "Spotlight")
        } catch {
            NewsFlowLogger.shared.error("Failed to deindex articles: \(error.localizedDescription)", category: "Spotlight")
        }
    }

    func deindexAll() async {
        do {
            try await searchableIndex.deleteAllSearchableItems()
            NewsFlowLogger.shared.info("Deindexed all articles from Spotlight", category: "Spotlight")
        } catch {
            NewsFlowLogger.shared.error("Failed to deindex all articles: \(error.localizedDescription)", category: "Spotlight")
        }
    }
}
