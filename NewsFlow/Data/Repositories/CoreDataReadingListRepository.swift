import CoreData
import Foundation

// MARK: - CoreDataReadingListRepository

/// Production-ready reading list repository backed by Core Data.
/// Provides thread-safe persistence with background context writes,
/// uniqueness constraints, and indexed fetch support.
actor CoreDataReadingListRepository: ReadingListRepositoryProtocol {
    private let coreDataStack: CoreDataStack

    init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
    }

    // MARK: - ReadingListRepositoryProtocol

    func savedArticleIDs() async -> Set<String> {
        let context = coreDataStack.newBackgroundContext()
        return await context.perform {
            let request = NSFetchRequest<ReadingListItem>(entityName: "ReadingListItem")
            request.propertiesToFetch = ["id"]
            do {
                let results = try context.fetch(request)
                return Set(results.map(\.id))
            } catch {
                NewsFlowLogger.shared.error(
                    "Failed to fetch saved article IDs: \(error.localizedDescription)",
                    category: "CoreData"
                )
                return []
            }
        }
    }

    func isSaved(articleID: String) async -> Bool {
        await fetchItem(withID: articleID) != nil
    }

    func add(_ article: Article) async throws {
        guard await !isSaved(articleID: article.id) else { return }
        let context = coreDataStack.newBackgroundContext()
        try await context.perform {
            let item = ReadingListItem(context: context)
            item.id = article.id
            item.title = article.title
            item.url = article.url?.absoluteString
            item.urlToImage = article.imageURL?.absoluteString
            item.publishedAt = article.publishedAt
            item.savedAt = Date()
            item.sourceID = article.sourceID
            do {
                try context.save()
                NewsFlowLogger.shared.info(
                    "Saved article to reading list: \(article.id)",
                    category: "CoreData"
                )
            } catch {
                NewsFlowLogger.shared.error(
                    "Failed to save article: \(error.localizedDescription)",
                    category: "CoreData"
                )
                throw error
            }
        }
    }

    func remove(articleID: String) async throws {
        let context = coreDataStack.newBackgroundContext()
        try await context.perform {
            let request = NSFetchRequest<ReadingListItem>(entityName: "ReadingListItem")
            request.predicate = NSPredicate(format: "id == %@", articleID)
            request.fetchLimit = 1
            do {
                if let item = try context.fetch(request).first {
                    context.delete(item)
                    try context.save()
                    NewsFlowLogger.shared.info(
                        "Removed article from reading list: \(articleID)",
                        category: "CoreData"
                    )
                }
            } catch {
                NewsFlowLogger.shared.error(
                    "Failed to remove article: \(error.localizedDescription)",
                    category: "CoreData"
                )
                throw error
            }
        }
    }

    func toggle(_ article: Article) async throws -> Bool {
        if await isSaved(articleID: article.id) {
            try await remove(articleID: article.id)
            return false
        }
        try await add(article)
        return true
    }

    // MARK: - Private

    private func fetchItem(withID id: String) async -> ReadingListItem? {
        let context = coreDataStack.newBackgroundContext()
        return await context.perform {
            let request = NSFetchRequest<ReadingListItem>(entityName: "ReadingListItem")
            request.predicate = NSPredicate(format: "id == %@", id)
            request.fetchLimit = 1
            return try? context.fetch(request).first
        }
    }
}
