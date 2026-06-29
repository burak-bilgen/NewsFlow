import Foundation


actor EnhancedArticleScorer {
    
    struct ArticleScore: Sendable {
        let recency: Double        // 0-28 - Fine-tuned exponential decay
        let quality: Double        // 0-22 - Enhanced content analysis
        let diversity: Double      // 0-18 - Content similarity penalty
        let engagement: Double     // 0-17 - Logarithmic scaling
        let sourceAuthority: Double // 0-15 - Expanded source list
        
        var total: Double {
            min(100, recency + quality + diversity + engagement + sourceAuthority)
        }
        
        var grade: ScoreGrade {
            switch total {
            case 92...100: return .excellent    // Top 5%
            case 80..<92: return .good         // Top 20%
            case 65..<80: return .average      // Middle 50%
            case 45..<65: return .belowAverage // Bottom 20%
            default: return .poor              // Bottom 5%
            }
        }
        
        enum ScoreGrade: String {
            case excellent = "A"
            case good = "B"
            case average = "C"
            case belowAverage = "D"
            case poor = "F"
        }
    }
    
    private enum Weights {
        static let recency: Double = 28
        static let quality: Double = 22
        static let diversity: Double = 18
        static let engagement: Double = 17
        static let authority: Double = 15
    }
    
    private enum RecencyParams {
        static let halfLife: Double = 6 // Hours - 50% score after 6 hours
        static let breakingThreshold: Double = 0.5 // 30 mins
        static let maxAge: Double = 168 // 1 week
    }
    
    private enum QualityParams {
        static let optimalTitleRange = 45...90
        static let optimalDescRange = 120...400
        static let minTitleLength = 20
        static let maxCapsRatio = 0.3 // Max 30% caps in title
    }
    
    private enum EngagementParams {
        static let viralThreshold: Double = 1000
        static let trendingThreshold: Double = 200
        static let hotThreshold: Double = 50
        static let logBase: Double = 10
    }
    
    private let now: Date
    private var sourceHistory: Set<String> = [] // Track sources for diversity
    
    init(now: Date = Date()) {
        self.now = now
    }
    
    
    func scoreAndEnrich(_ articles: [Article]) async -> [Article] {
        sourceHistory.removeAll()
        
        var scoredArticles: [(article: Article, score: ArticleScore)] = []
        
        for article in articles {
            let score = await calculateScore(for: article)
            var enrichedArticle = article
            enrichedArticle.qualityScore = score.total
            scoredArticles.append((enrichedArticle, score))
        }
        
        scoredArticles.sort { $0.score.total > $1.score.total }
        
        return scoredArticles.map { $0.article }
    }
    
    
    private func calculateScore(for article: Article) async -> ArticleScore {
        async let recency = calculateRecencyScore(article)
        async let quality = calculateQualityScore(article)
        async let diversity = calculateDiversityScore(article)
        async let engagement = calculateEngagementScore(article)
        async let authority = calculateSourceAuthority(article)
        
        return await ArticleScore(
            recency: recency,
            quality: quality,
            diversity: diversity,
            engagement: engagement,
            sourceAuthority: authority
        )
    }
    
    private func calculateRecencyScore(_ article: Article) async -> Double {
        guard let publishedAt = article.publishedAt else { return 0 }
        
        let hoursAgo = now.timeIntervalSince(publishedAt) / 3600
        
        let decayFactor = pow(0.5, hoursAgo / RecencyParams.halfLife)
        var score = Weights.recency * decayFactor
        
        if hoursAgo < RecencyParams.breakingThreshold {
            score *= 1.15 // 15% bonus for fresh news
        }
        
        if hoursAgo > RecencyParams.maxAge {
            score *= 0.5
        }
        
        if hoursAgo < 24 {
            score = max(score, 18) // Minimum 18 for today
        }
        
        return min(Weights.recency, score)
    }
    
    private func calculateQualityScore(_ article: Article) async -> Double {
        var score: Double = 0
        
        let titleLength = article.title.count
        let titleScore = calculateTitleQuality(title: article.title, length: titleLength)
        score += titleScore * 8 // Up to 8 points
        
        if let desc = article.description {
            let descLength = desc.count
            if QualityParams.optimalDescRange.contains(descLength) {
                score += 6
            } else if descLength > 200 {
                score += 4
            } else if descLength > 50 {
                score += 2
            }
            
            let sentenceCount = desc.components(separatedBy: ".").count
            if sentenceCount >= 3 {
                score += 2 // Well-formed description
            }
        }
        
        if article.imageURL != nil {
            score += 5 // Visual content bonus
        }
        
        if let snippet = article.contentSnippet {
            let snippetLength = snippet.count
            if snippetLength > 1000 {
                score += 4 // Deep content
            } else if snippetLength > 500 {
                score += 2
            }
        }
        
        if let url = article.url?.absoluteString {
            if url.hasPrefix("https") {
                score += 1
            }
        }
        
        return min(Weights.quality, score)
    }
    
    private func calculateTitleQuality(title: String, length: Int) -> Double {
        var quality: Double = 0
        
        if QualityParams.optimalTitleRange.contains(length) {
            quality += 0.5
        } else if length >= QualityParams.minTitleLength {
            quality += 0.3
        }
        
        let words = title.split(separator: " ")
        if words.count >= 5 && words.count <= 15 {
            quality += 0.3
        }
        
        let capsCount = title.filter { $0.isUppercase }.count
        let capsRatio = Double(capsCount) / Double(length)
        if capsRatio < QualityParams.maxCapsRatio {
            quality += 0.2
        }
        
        let substanceWords = ["announces", "launches", "reports", "study", "research", "data", "analysis"]
        let hasSubstance = substanceWords.contains { title.lowercased().contains($0) }
        if hasSubstance {
            quality += 0.2
        }
        
        return min(1.0, quality)
    }
    
    private func calculateDiversityScore(_ article: Article) async -> Double {
        var score = Weights.diversity * 0.6 // Base 60%
        
        let sourceLower = article.sourceName.lowercased()
        if sourceHistory.contains(sourceLower) {
            score *= 0.85
        }
        sourceHistory.insert(sourceLower)
        
        let hasImage = article.imageURL != nil
        let hasDescription = (article.description?.count ?? 0) > 100
        let hasSnippet = (article.contentSnippet?.count ?? 0) > 500
        
        let richnessScore = [hasImage, hasDescription, hasSnippet].filter { $0 }.count
        score += Double(richnessScore) * 1.5
        
        return min(Weights.diversity, score)
    }
    
    private func calculateEngagementScore(_ article: Article) async -> Double {
        guard let engagement = article.engagementScore, engagement > 0 else {
            return Weights.engagement * 0.3 // Base 30% for unknown engagement
        }
        
        let logScore = log(engagement + 1) / log(EngagementParams.logBase)
        var score = min(Weights.engagement, logScore * 6)
        
        if engagement > EngagementParams.viralThreshold {
            score += 2 // Small bonus for viral
        } else if engagement > EngagementParams.trendingThreshold {
            score += 1
        }
        
        return min(Weights.engagement, score)
    }
    
    private func calculateSourceAuthority(_ article: Article) async -> Double {
        let authorityScores: [String: Double] = [
            "bbc": 15, "reuters": 15, "associated press": 15, "ap": 15,
            "new york times": 14, "nyt": 14,
            "the guardian": 14, "guardian": 14,
            "wall street journal": 14, "wsj": 14,
            "washington post": 13, "financial times": 13, "economist": 13,
            "nature": 14, "science": 13, "scientific american": 13,
            
            "the verge": 12, "wired": 12, "ars technica": 12,
            "bloomberg": 13, "business insider": 11, "fortune": 12,
            "techcrunch": 11, "the information": 12,
            "axios": 12, "politico": 12,
            
            "hackernews": 10, "hacker news": 10,
            "gnews": 9, "newsdata": 9,
            "newsapi": 8, "news api": 8,
            
            "usa today": 10, "cnn": 9, "abc news": 9, "nbc news": 9, "cbs news": 9,
            "fox news": 8, "npr": 10, "pbs": 10,
            "al jazeera": 11, "deutsche welle": 10, "france24": 10,
            
            "engadget": 9, "gizmodo": 9, "cnet": 9, "zdnet": 9,
            "slashdot": 9, "product hunt": 9,
            
            "marketwatch": 10, "seeking alpha": 9, "investopedia": 10,
            "cnbc": 10, "yahoo finance": 9,
        ]
        
        let sourceLower = article.sourceName.lowercased()
        let baseScore = authorityScores[sourceLower] ?? 6 // Default for unknown sources
        
        if let url = article.url?.absoluteString {
            if url.contains(".edu") || url.contains(".gov") {
                return min(Weights.authority, baseScore + 2)
            }
        }
        
        return min(Weights.authority, baseScore)
    }
    
    
    func calculateDuplicatePenalty(_ article: Article, against existingArticles: [Article]) -> Double {
        let articleText = (article.title + " " + (article.description ?? "")).lowercased()
        
        for existing in existingArticles {
            let existingText = (existing.title + " " + (existing.description ?? "")).lowercased()
            
            let articleWords = Set(articleText.split(separator: " "))
            let existingWords = Set(existingText.split(separator: " "))
            
            let intersection = articleWords.intersection(existingWords).count
            let union = articleWords.union(existingWords).count
            
            let similarity = Double(intersection) / Double(union)
            
            if similarity > 0.7 {
                return 0.5 // 50% penalty for duplicates
            } else if similarity > 0.5 {
                return 0.8 // 20% penalty for near-duplicates
            }
        }
        
        return 1.0 // No penalty
    }
    
    func isTimeSensitive(_ article: Article) -> Bool {
        let timeSensitiveWords = [
            "breaking", "just", "update", "developing", "live", "urgent",
            "now", "today", "latest", "announces", "reveals", "unveils",
            "launches", "releases", "debuts", "premieres"
        ]
        
        let text = (article.title + " " + (article.description ?? "")).lowercased()
        let wordCount = timeSensitiveWords.filter { text.contains($0) }.count
        
        return wordCount >= 2 || text.contains("breaking")
    }
    
    func calculateVerificationBonus(_ article: Article, allArticles: [Article]) -> Double {
        let articleKeyTerms = extractKeyTerms(article.title)
        var verificationCount = 0
        
        for other in allArticles {
            guard other.id != article.id else { continue }
            guard other.sourceName != article.sourceName else { continue }
            
            let otherTerms = extractKeyTerms(other.title)
            let commonTerms = articleKeyTerms.intersection(otherTerms)
            
            if commonTerms.count >= 3 {
                verificationCount += 1
            }
        }
        
        switch verificationCount {
        case 0: return 0
        case 1: return 1 // 1 other source confirms
        case 2...3: return 2 // 2-3 sources confirm
        default: return 3 // 4+ sources (major story)
        }
    }
    
    private func extractKeyTerms(_ title: String) -> Set<String> {
        let stopWords = Set(["the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by"])
        let words = title.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 3 }
            .filter { !stopWords.contains($0) }
        
        return Set(words)
    }
    
}


extension EnhancedArticleScorer {
    
    func scoreAndEnrichWithDuplicates(_ articles: [Article]) async -> [Article] {
        var scoredArticles: [(article: Article, score: ArticleScore)] = []
        var processedArticles: [Article] = []
        
        for article in articles {
            let baseScore = await calculateScore(for: article)
            
            let duplicatePenalty = calculateDuplicatePenalty(article, against: processedArticles)
            
            let verificationBonus = calculateVerificationBonus(article, allArticles: articles)
            
            let adjustedDiversity = baseScore.diversity * duplicatePenalty + verificationBonus
            
            let finalScore = ArticleScore(
                recency: baseScore.recency,
                quality: baseScore.quality,
                diversity: min(18, adjustedDiversity),
                engagement: baseScore.engagement,
                sourceAuthority: baseScore.sourceAuthority
            )
            
            var enrichedArticle = article
            enrichedArticle.qualityScore = finalScore.total
            enrichedArticle.engagementScore = baseScore.engagement
            
            if isTimeSensitive(article) {
            }
            
            scoredArticles.append((enrichedArticle, finalScore))
            processedArticles.append(article)
        }
        
        scoredArticles.sort { $0.score.total > $1.score.total }
        
        return scoredArticles.map { $0.article }
    }
}
