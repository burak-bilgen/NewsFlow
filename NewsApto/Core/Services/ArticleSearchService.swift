import Foundation

// MARK: - Advanced Article Search Service
// Fuzzy search with ranking, typo tolerance, and multi-field search

actor ArticleSearchService {
    
    struct SearchResult: Sendable {
        let article: Article
        let relevanceScore: Double
        let matchedFields: [SearchField]
        let matchType: MatchType
        
        enum SearchField: String, Sendable {
            case title = "Title"
            case description = "Description"
            case content = "Content"
            case source = "Source"
        }
        
        enum MatchType: String, Sendable {
            case exact = "Exact"
            case prefix = "Prefix"
            case fuzzy = "Fuzzy"
            case partial = "Partial"
        }
    }
    
    struct SearchOptions: Sendable {
        let fuzzyThreshold: Double        // 0.0-1.0, default 0.6
        let maxResults: Int               // Default 50
        let searchContentSnippet: Bool    // Default true
        let caseSensitive: Bool           // Default false
        let minRelevanceScore: Double     // Default 0.1
        
        static let `default` = SearchOptions(
            fuzzyThreshold: 0.6,
            maxResults: 50,
            searchContentSnippet: true,
            caseSensitive: false,
            minRelevanceScore: 0.1
        )
    }
    
    // MARK: - Search Methods
    
    func search(
        query: String,
        in articles: [Article],
        options: SearchOptions = .default
    ) async -> [SearchResult] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
        guard !trimmedQuery.isEmpty else { return [] }
        
        // Split query into terms (AND logic)
        let searchTerms = trimmedQuery
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count >= 2 } // Ignore single chars
        
        guard !searchTerms.isEmpty else { return [] }
        
        var results: [SearchResult] = []
        
        for article in articles {
            if let result = scoreArticle(
                article: article,
                searchTerms: searchTerms,
                options: options
            ) {
                results.append(result)
            }
        }
        
        // Sort by relevance score descending
        results.sort { $0.relevanceScore > $1.relevanceScore }
        
        // Return top results
        return Array(results.prefix(options.maxResults))
    }
    
    // MARK: - Article Scoring
    
    private func scoreArticle(
        article: Article,
        searchTerms: [String],
        options: SearchOptions
    ) -> SearchResult? {
        var totalScore: Double = 0
        var matchedFields: Set<SearchResult.SearchField> = []
        var bestMatchType: SearchResult.MatchType = .partial
        
        let searchableContent = prepareSearchableContent(from: article, options: options)
        
        for term in searchTerms {
            let (score, field, matchType) = scoreTerm(
                term: term,
                in: searchableContent,
                options: options
            )
            
            // All terms must match (AND logic)
            if score == 0 {
                return nil
            }
            
            totalScore += score
            if let field = field {
                matchedFields.insert(field)
            }
            
            // Upgrade match type if better
            if matchTypePriority(matchType) > matchTypePriority(bestMatchType) {
                bestMatchType = matchType
            }
        }
        
        // Normalize score by term count
        let normalizedScore = totalScore / Double(searchTerms.count)
        
        guard normalizedScore >= options.minRelevanceScore else {
            return nil
        }
        
        // Boost score based on match quality
        var finalScore = normalizedScore
        
        // Title match is most valuable
        if matchedFields.contains(.title) {
            finalScore *= 1.5
        }
        
        // Exact matches are better
        if bestMatchType == .exact {
            finalScore *= 1.3
        }
        
        // Multiple field matches are good
        finalScore *= (1.0 + Double(matchedFields.count) * 0.1)
        
        return SearchResult(
            article: article,
            relevanceScore: min(100, finalScore * 100),
            matchedFields: Array(matchedFields),
            matchType: bestMatchType
        )
    }
    
    // MARK: - Term Scoring
    
    private func scoreTerm(
        term: String,
        in content: SearchableContent,
        options: SearchOptions
    ) -> (score: Double, field: SearchResult.SearchField?, matchType: SearchResult.MatchType) {
        var bestScore: Double = 0
        var bestField: SearchResult.SearchField?
        var bestMatchType: SearchResult.MatchType = .partial
        
        // Check title (highest priority)
        if let (score, type) = matchScore(term: term, text: content.title, options: options) {
            if score > bestScore {
                bestScore = score * 3.0 // Title multiplier
                bestField = .title
                bestMatchType = type
            }
        }
        
        // Check source name
        if let (score, type) = matchScore(term: term, text: content.source, options: options) {
            if score > bestScore {
                bestScore = score * 1.5 // Source multiplier
                bestField = .source
                bestMatchType = type
            }
        }
        
        // Check description
        if let (score, type) = matchScore(term: term, text: content.description, options: options) {
            if score > bestScore {
                bestScore = score * 1.2 // Description multiplier
                bestField = .description
                bestMatchType = type
            }
        }
        
        // Check content snippet
        if options.searchContentSnippet,
           let (score, type) = matchScore(term: term, text: content.contentSnippet, options: options) {
            if score > bestScore {
                bestScore = score // Base multiplier
                bestField = .content
                bestMatchType = type
            }
        }
        
        return (bestScore, bestField, bestMatchType)
    }
    
    // MARK: - Match Algorithms
    
    private func matchScore(
        term: String,
        text: String,
        options: SearchOptions
    ) -> (score: Double, type: SearchResult.MatchType)? {
        let textLower = text.lowercased()
        let termLower = term.lowercased()
        
        // Exact match
        if textLower == termLower {
            return (1.0, .exact)
        }
        
        // Prefix match (word starts with term)
        let words = textLower.components(separatedBy: .alphanumerics.inverted)
        for word in words {
            if word.hasPrefix(termLower) {
                let score = Double(term.count) / Double(word.count)
                return (max(0.7, score), .prefix)
            }
        }
        
        // Contains match
        if textLower.contains(termLower) {
            // Score based on position (earlier is better)
            let position = textLower.range(of: termLower)?.lowerBound
            let positionScore = position.map {
                1.0 - (Double(textLower.distance(from: textLower.startIndex, to: $0)) / Double(textLower.count) * 0.3)
            } ?? 0.8
            
            return (positionScore * 0.8, .partial)
        }
        
        // Fuzzy match (for typos)
        for word in words where word.count >= term.count {
            let similarity = calculateSimilarity(termLower, word)
            if similarity >= options.fuzzyThreshold {
                return (similarity * 0.6, .fuzzy)
            }
        }
        
        return nil
    }
    
    // MARK: - Fuzzy Matching
    
    private func calculateSimilarity(_ s1: String, _ s2: String) -> Double {
        let maxDistance = max(s1.count, s2.count)
        guard maxDistance > 0 else { return 1.0 }
        
        let distance = levenshteinDistance(s1, s2)
        return 1.0 - (Double(distance) / Double(maxDistance))
    }
    
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        
        let rows = s1Array.count + 1
        let cols = s2Array.count + 1
        
        var matrix = Array(repeating: Array(repeating: 0, count: cols), count: rows)
        
        for i in 0..<rows {
            matrix[i][0] = i
        }
        for j in 0..<cols {
            matrix[0][j] = j
        }
        
        for i in 1..<rows {
            for j in 1..<cols {
                let cost = s1Array[i-1] == s2Array[j-1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i-1][j] + 1,      // deletion
                    matrix[i][j-1] + 1,      // insertion
                    matrix[i-1][j-1] + cost  // substitution
                )
            }
        }
        
        return matrix[rows-1][cols-1]
    }
    
    // MARK: - Helpers
    
    private func prepareSearchableContent(from article: Article, options: SearchOptions) -> SearchableContent {
        return SearchableContent(
            title: options.caseSensitive ? article.title : article.title.lowercased(),
            description: article.description?.lowercased() ?? "",
            contentSnippet: article.contentSnippet?.lowercased() ?? "",
            source: article.sourceName.lowercased()
        )
    }
    
    private func matchTypePriority(_ type: SearchResult.MatchType) -> Int {
        switch type {
        case .exact: return 4
        case .prefix: return 3
        case .fuzzy: return 2
        case .partial: return 1
        }
    }
    
    private struct SearchableContent {
        let title: String
        let description: String
        let contentSnippet: String
        let source: String
    }
}

// MARK: - Search Extensions

extension ArticleSearchService.SearchResult {
    /// Highlights matched terms in text
    func highlightedTitle(query: String) -> String {
        // Simple highlight - in real app, use AttributedString
        return article.title
    }
    
    /// Returns a relevance description for debugging
    var relevanceDescription: String {
        let fields = matchedFields.map { $0.rawValue }.joined(separator: ", ")
        return "\(matchType.rawValue) match in \(fields) - Score: \(String(format: "%.1f", relevanceScore))"
    }
}
