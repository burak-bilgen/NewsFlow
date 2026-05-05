import CoreData
import Foundation

// MARK: - Core Data Stack

/// Manages the Core Data persistent container and context lifecycle.
/// Uses a shared singleton for the main app target.
final class CoreDataStack {
    static let shared = CoreDataStack()

    init() {}

    lazy var persistentContainer: NSPersistentContainer = {
        guard let modelURL = Bundle.main.url(
            forResource: "NewsFlowModel",
            withExtension: "momd"
        ) else {
            fatalError("Failed to locate Core Data model: NewsFlowModel")
        }

        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to load Core Data model: NewsFlowModel")
        }

        let container = NSPersistentContainer(name: "NewsFlowModel", managedObjectModel: model)
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved Core Data error: \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()

    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
}
