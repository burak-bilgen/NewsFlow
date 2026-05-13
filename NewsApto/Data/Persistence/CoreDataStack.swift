import CoreData
import Foundation

final class CoreDataStack: @unchecked Sendable {
    static let shared = CoreDataStack()

    private var _container: NSPersistentContainer?
    private let lock = NSLock()
    private init() {}

    var persistentContainer: NSPersistentContainer {
        lock.lock()
        defer { lock.unlock() }
        if let container = _container { return container }
        let container: NSPersistentContainer
        if let modelURL = Bundle.main.url(forResource: "NewsAptoModel", withExtension: "momd"),
           let model = NSManagedObjectModel(contentsOf: modelURL) {
            container = NSPersistentContainer(name: "NewsAptoModel", managedObjectModel: model)
        } else {
            NewsAptoLogger.shared.warning("Core Data model not found, using fallback", category: "CoreData")
            container = NSPersistentContainer(name: "NewsAptoModel")
        }
        container.loadPersistentStores { _, error in
            if let error = error {
                NewsAptoLogger.shared.error("Persistent store error: \(error.localizedDescription)", category: "CoreData")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        _container = container
        return container
    }

    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
}
