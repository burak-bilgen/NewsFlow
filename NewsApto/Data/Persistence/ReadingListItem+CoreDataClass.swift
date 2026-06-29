import CoreData
import Foundation


@objc(ReadingListItem)
public class ReadingListItem: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var title: String
    @NSManaged public var articleDescription: String?
    @NSManaged public var url: String?
    @NSManaged public var urlToImage: String?
    @NSManaged public var publishedAt: Date?
    @NSManaged public var savedAt: Date
    @NSManaged public var sourceID: String
    @NSManaged public var sourceName: String?
}
