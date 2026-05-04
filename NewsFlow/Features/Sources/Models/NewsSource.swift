import Foundation

struct NewsSource: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let description: String
    let category: String
    let language: String
}
