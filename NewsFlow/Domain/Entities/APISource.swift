import Foundation

enum APISource: String, Codable, Sendable, CaseIterable {
    case newsAPI = "newsapi"
    case guardian = "guardian"
    case nyt = "nyt"
}
