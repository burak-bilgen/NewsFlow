import Foundation
import NaturalLanguage

enum AIAvailability: Equatable {
    case available
    case disabled(String)
    case unavailable(String)

    var isAvailable: Bool { self == .available }

    var message: String? {
        switch self {
        case .available: return nil
        case .disabled(let msg): return msg
        case .unavailable(let msg): return msg
        }
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
            return .disabled("Apple Intelligence is available but may be disabled in Settings. Enable it for AI-powered summaries.")
        }
        return .unavailable("AI features require iOS 18+")
    }

    func generateSummary(for text: String) async -> String? {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return smartSummary(for: text)
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
            score += min(desc.split(separator: " ").count / 5, 8)
        }
        if article.title.split(separator: " ").count >= 5 { score += 5 }
        return score
    }

    private func smartSummary(for text: String) -> String? {
        guard !text.isEmpty else { return nil }
        let sentences = text.components(separatedBy: ". ")
        if sentences.count <= 2 { return text }
        let extracted = sentences.prefix(2).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        guard !extracted.isEmpty else { return nil }
        return extracted.joined(separator: ". ") + "."
    }
}

final class FallbackIntelligenceService: IntelligenceServicing {
    let availability: AIAvailability = .unavailable("Using standard sorting — no AI features available")
    private let scorer = SmartArticleScorer()

    func generateSummary(for text: String) async -> String? {
        guard !text.isEmpty else { return nil }
        let sentences = text.components(separatedBy: ". ")
        if sentences.count <= 2 { return text }
        let extracted = sentences.prefix(2).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        guard !extracted.isEmpty else { return nil }
        return extracted.joined(separator: ". ") + "."
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
        if #available(iOS 18, *) {
            NewsFlowLogger.shared.info("Device supports iOS 18 — Apple Intelligence is available", category: "AI")
            return AppleIntelligenceService()
        }
        NewsFlowLogger.shared.info("iOS 18 not available — using fallback service", category: "AI")
        return FallbackIntelligenceService()
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
