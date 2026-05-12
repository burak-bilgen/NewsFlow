import Foundation
import NaturalLanguage

enum AIAvailability: Equatable {
    case available
    case unavailable(String)

    var isAvailable: Bool {
        if case .available = self { return true }
        return false
    }
}

protocol IntelligenceServicing {
    var availability: AIAvailability { get }
    func generateSummary(for text: String) async -> String?
    func extractTopics(from text: String) -> [String]
    func importanceScore(for article: Article) async -> Int
}

final class AppleIntelligenceService: IntelligenceServicing {
    static let shared = AppleIntelligenceService()

    var availability: AIAvailability {
        if #available(iOS 18, *) {
            return .available
        }
        return .unavailable("Requires iOS 18+")
    }

    func generateSummary(for text: String) async -> String? {
        guard #available(iOS 18, *) else { return fallbackSummary(for: text) }
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return fallbackSummary(for: text)
    }

    func extractTopics(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        var topics: [String] = []

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: [.omitPunctuation, .omitWhitespace, .joinNames]) { tag, tokenRange in
            if tag == .placeName || tag == .organizationName || tag == .personalName {
                topics.append(String(text[tokenRange]))
            }
            return true
        }

        return Array(Set(topics)).prefix(5).map { $0 }
    }

    func importanceScore(for article: Article) async -> Int {
        var score = 0

        if let description = article.description {
            let topics = extractTopics(from: description)
            score += min(topics.count * 3, 15)
        }

        if let publishedAt = article.publishedAt {
            let hoursAgo = Date().timeIntervalSince(publishedAt) / 3600
            if hoursAgo < 3 { score += 25 }
            else if hoursAgo < 6 { score += 20 }
            else if hoursAgo < 12 { score += 15 }
            else if hoursAgo < 24 { score += 10 }
            else if hoursAgo < 48 { score += 5 }
            else { score += 2 }
        }

        if article.imageURL != nil { score += 12 }
        if let desc = article.description {
            let wordCount = desc.split(separator: " ").count
            score += min(wordCount / 5, 8)
        }

        let titleLength = article.title.split(separator: " ").count
        if titleLength >= 5 { score += 5 }

        return score
    }

    private func fallbackSummary(for text: String) -> String? {
        guard !text.isEmpty else { return nil }
        let words = text.split(separator: " ")
        if words.count <= 55 { return text }
        return words.prefix(55).joined(separator: " ") + "..."
    }
}

final class FallbackIntelligenceService: IntelligenceServicing {
    let availability: AIAvailability = .unavailable("Fallback")
    private let scorer = SmartArticleScorer()

    func generateSummary(for text: String) async -> String? {
        guard !text.isEmpty else { return nil }
        let words = text.split(separator: " ")
        if words.count <= 50 { return text }
        return words.prefix(50).joined(separator: " ") + "..."
    }

    func extractTopics(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        var topics: [String] = []
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: [.omitPunctuation, .omitWhitespace, .joinNames]) { tag, tokenRange in
            if tag == .placeName || tag == .organizationName || tag == .personalName {
                topics.append(String(text[tokenRange]))
            }
            return true
        }
        return Array(Set(topics)).prefix(3).map { $0 }
    }

    func importanceScore(for article: Article) async -> Int {
        let scored = scorer.score([article])
        return scored.first?.score ?? 50
    }
}

enum IntelligenceFactory {
    static func make() -> IntelligenceServicing {
        let ai = AppleIntelligenceService()
        if ai.availability.isAvailable {
            NewsFlowLogger.shared.info("Apple Intelligence available", category: "AI")
            return ai
        }
        NewsFlowLogger.shared.info("Apple Intelligence unavailable, using fallback", category: "AI")
        return FallbackIntelligenceService()
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
