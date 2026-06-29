import Foundation
import NaturalLanguage


actor TopicDiversityEngine {
    
    private let tagger: NLTagger
    private var topicCache: [String: String] = [:] // articleID -> topicID
    private var usedTopics: Set<String> = []
    
    init() {
        self.tagger = NLTagger(tagSchemes: [.lemma, .nameType])
    }
    
    
    func extractTopicID(from article: Article) async -> String {
        if let cached = topicCache[article.id] {
            return cached
        }
        
        let text = "\(article.title) \(article.description ?? "")"
        let keywords = extractKeywords(from: text)
        
        let topicID = keywords.sorted().joined(separator: "-").lowercased()
            .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
            .prefix(50)
            .description
        
        topicCache[article.id] = topicID
        return topicID
    }
    
    func extractKeywords(from text: String) -> [String] {
        tagger.string = text
        
        var keywords: [String] = []
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lemma, options: options) { tag, range in
            if let tag = tag, tag.rawValue.count > 2 {
                let word = String(text[range]).lowercased()
                if !isStopWord(word) {
                    keywords.append(word)
                }
            }
            return true
        }
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: options) { tag, range in
            if let tag = tag, (tag == .placeName || tag == .personalName || tag == .organizationName) {
                let entity = String(text[range]).lowercased()
                keywords.append(entity)
            }
            return true
        }
        
        let frequency = keywords.reduce(into: [:]) { counts, word in counts[word, default: 0] += 1 }
        return Array(frequency.sorted { $0.value > $1.value }.prefix(5).map { $0.key })
    }
    
    
    func ensureDiversity(in articles: [Article], maxPerTopic: Int = 2, minArticles: Int = 15) async -> [Article] {
        guard articles.count >= minArticles else { return articles }
        var topicCounts: [String: Int] = [:]
        var diverseArticles: [Article] = []
        
        for article in articles {
            let topicID = await extractTopicID(from: article)
            let currentCount = topicCounts[topicID, default: 0]
            
            if currentCount < maxPerTopic {
                diverseArticles.append(article)
                topicCounts[topicID] = currentCount + 1
            }
        }
        
        return diverseArticles
    }
    
    
    func calculateSimilarity(between article1: Article, and article2: Article) async -> Double {
        let topic1 = await extractTopicID(from: article1)
        let topic2 = await extractTopicID(from: article2)
        
        let keywords1 = Set(topic1.split(separator: "-").map(String.init))
        let keywords2 = Set(topic2.split(separator: "-").map(String.init))
        
        let intersection = keywords1.intersection(keywords2)
        let union = keywords1.union(keywords2)
        
        guard !union.isEmpty else { return 0 }
        return Double(intersection.count) / Double(union.count)
    }
    
    
    private func isStopWord(_ word: String) -> Bool {
        let stopWords: Set<String> = [
            "the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for",
            "of", "with", "by", "from", "as", "is", "was", "are", "were", "be",
            "been", "being", "have", "has", "had", "do", "does", "did", "will",
            "would", "could", "should", "may", "might", "must", "shall", "can",
            "need", "dare", "ought", "used", "said", "says", "say", "get", "got",
            "go", "went", "come", "came", "see", "saw", "know", "knew", "think",
            "thought", "take", "took", "make", "made", "this", "that", "these",
            "those", "i", "you", "he", "she", "it", "we", "they", "me", "him",
            "her", "us", "them", "my", "your", "his", "hers", "its", "our", "their"
        ]
        return stopWords.contains(word)
    }
    
    func resetCache() {
        topicCache.removeAll()
        usedTopics.removeAll()
    }
}
