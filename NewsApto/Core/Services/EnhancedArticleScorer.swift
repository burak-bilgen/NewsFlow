import Foundation
import NaturalLanguage

// MARK: - Enhanced Article Scorer
// 5-factor scoring system for intelligent curation

actor EnhancedArticleScorer {
    
    struct ArticleScore: Sendable {
        let recency: Double        // 0-25
        let quality: Double        // 0-20
        let diversity: Double      // 0-20
        let engagement: Double     // 0-20
        let sourceAuthority: Double // 0-15
        
        var total: Double {
            min(100, recency + quality + diversity + engagement + sourceAuthority)
        }
        
        var grade: ScoreGrade {
            switch total {
            case 90...100: return .excellent
            case 75..<90: return .good
            case 60..<75: return .average
            case 40..<60: return .belowAverage
            default: return .poor
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
    
    private let now: Date
    private let userProfile: UserPreferenceProfile?
    private let topicExtractor: TopicDiversityEngine
    
    init(now: Date = Date(), userProfile: UserPreferenceProfile? = nil) {
        self.now = now
        self.userProfile = userProfile
        self.topicExtractor = TopicDiversityEngine()
    }
    
    // MARK: - Main Scoring Method
    
    func scoreAndEnrich(_ articles: [Article]) async -> [Article] {
        var scoredArticles: [(article: Article, score: ArticleScore)] = []
        
        for article in articles {
            let score = await calculateScore(for: article)
            var enrichedArticle = article
            enrichedArticle.qualityScore = score.total
            enrichedArticle.topicID = await topicExtractor.extractTopicID(from: article)
            enrichedArticle.badges = determineBadges(article: article, score: score)
            enrichedArticle.curationReason = generateCurationReason(score: score, article: article)
            scoredArticles.append((enrichedArticle, score))
        }
        
        // Sort by total score descending
        scoredArticles.sort { $0.score.total > $1.score.total }
        
        return scoredArticles.map { $0.article }
    }
    
    // MARK: - Individual Score Calculations
    
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
        
        switch hoursAgo {
        case ..<1:   return 25  // Breaking news
        case ..<3:   return 22
        case ..<6:   return 19
        case ..<12:  return 16
        case ..<24:  return 13  // Today
        case ..<48:  return 9   // Yesterday
        case ..<72:  return 6   // This week
        case ..<168: return 3   // Last week
        default:     return 1   // Older
        }
    }
    
    private func calculateQualityScore(_ article: Article) async -> Double {
        var score: Double = 0
        
        // Content length scoring
        let titleLength = article.title.count
        if titleLength >= 30 && titleLength <= 100 {
            score += 5  // Optimal title length
        } else if titleLength > 100 {
            score += 3
        } else {
            score += 1
        }
        
        // Description quality
        if let desc = article.description {
            let descLength = desc.count
            if descLength >= 100 && descLength <= 500 {
                score += 5
            } else if descLength > 50 {
                score += 3
            }
        }
        
        // Has image
        if article.imageURL != nil {
            score += 5
        }
        
        // Content snippet available
        if let snippet = article.contentSnippet, !snippet.isEmpty {
            score += 3
        }
        
        // URL quality (HTTPS preferred)
        if let url = article.url?.absoluteString, url.hasPrefix("https") {
            score += 2
        }
        
        return min(20, score)
    }
    
    private func calculateDiversityScore(_ article: Article) async -> Double {
        // This will be calculated at aggregate level in topic diversity engine
        // Individual article gets base score
        return 10
    }
    
    private func calculateEngagementScore(_ article: Article) async -> Double {
        var score: Double = 0
        
        // HN/Reddit scores
        if let engagement = article.engagementScore {
            if engagement > 500 { score += 20 }
            else if engagement > 100 { score += 15 }
            else if engagement > 50 { score += 10 }
            else if engagement > 10 { score += 5 }
        }
        
        // User preference matching
        if let profile = userProfile {
            let categoryScore = profile.preferredCategories[article.sourceName] ?? 0
            score += categoryScore * 10
        }
        
        return min(20, score)
    }
    
    private func calculateSourceAuthority(_ article: Article) async -> Double {
        let authorityScores: [String: Double] = [
            // Tier 1: Major global outlets
            "bbc": 15, "reuters": 15, "associated press": 15, "ap": 15,
            "new york times": 14, "the guardian": 14, "wall street journal": 14,
            "washington post": 13, "financial times": 13, "economist": 13,
            
            // Tier 2: Quality tech/business
            "the verge": 12, "techcrunch": 11, "wired": 12, "ars technica": 12,
            "bloomberg": 13, "cnbc": 11, "forbes": 10,
            
            // Tier 3: Good sources
            "hackernews": 11, "gnews": 10, "newsdata": 9,
            "newsapi": 8, "guardian": 13, "nyt": 14,
            
            // Default for unknown
        ]
        
        let sourceLower = article.sourceName.lowercased()
        return authorityScores[sourceLower] ?? 7  // Default for unknown sources
    }
    
    // MARK: - Badge Determination
    
    private func determineBadges(article: Article, score: ArticleScore) -> [Article.ArticleBadge] {
        var badges: [Article.ArticleBadge] = []
        
        // Breaking: Very recent + good quality
        if score.recency >= 22 && score.quality >= 12 {
            badges.append(.breaking)
        }
        
        // Trending: High engagement
        if let engagement = article.engagementScore, engagement > 100 {
            badges.append(.trending)
        }
        
        // Editor's Choice: Top overall score
        if score.total >= 85 {
            badges.append(.editorsChoice)
        }
        
        // High Quality: Good content metrics
        if score.quality >= 16 {
            badges.append(.highQuality)
        }
        
        // Personalized: Matches user interests
        if score.engagement >= 10 {
            badges.append(.personalized)
        }
        
        return badges
    }
    
    // MARK: - Curation Reason
    
    private func generateCurationReason(score: ArticleScore, article: Article) -> Article.CurationReason {
        var factors: [String] = []
        
        if score.recency >= 22 {
            factors.append("⚡ Breaking news")
        } else if score.recency >= 13 {
            factors.append("🕐 Recent")
        }
        
        if score.quality >= 16 {
            factors.append("⭐ High quality")
        }
        
        if score.sourceAuthority >= 12 {
            factors.append("📰 Trusted source")
        }
        
        if score.engagement >= 10 {
            factors.append("🔥 Trending")
        }
        
        let reason = factors.isEmpty ? "Curated for you" : factors.joined(separator: " • ")
        
        return Article.CurationReason(reason: reason, factors: factors)
    }
}

// MARK: - User Preference Profile

struct UserPreferenceProfile: Sendable {
    var preferredCategories: [String: Double] = [:]
    var preferredSources: [String: Double] = [:]
    var readingTimePattern: ReadingTimePattern = .evening
    var contentDepth: ContentDepthPreference = .balanced
    
    enum ReadingTimePattern: String, Sendable {
        case morning = "Morning"
        case afternoon = "Afternoon"
        case evening = "Evening"
        case night = "Night"
    }
    
    enum ContentDepthPreference: String, Sendable {
        case quick = "Quick updates"
        case balanced = "Balanced"
        case deep = "Deep dives"
    }
}
