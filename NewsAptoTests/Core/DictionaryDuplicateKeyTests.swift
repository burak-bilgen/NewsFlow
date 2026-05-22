import XCTest
@testable import NewsApto

final class DictionaryDuplicateKeyTests: XCTestCase {
    
    func testCategoryMappingsNoDuplicates() {
        // This will crash at runtime if there are duplicate keys
        let mappings: [String: String] = [
            // Technology
            "technology": "technology", "tech": "technology", "science-and-technology": "technology",
            "computers": "technology", "internet": "technology", "gadgets": "technology",
            "mobile": "technology", "telecommunications": "technology", "ai": "technology",
            "artificial-intelligence": "technology", "cyber-security": "technology",
            "cybersecurity": "technology", "programming": "technology", "software": "technology",
            "startups": "technology", "innovation": "technology", "scienceandtechnology": "technology",
            "top": "technology", "technology-technology": "technology",
            
            // Business
            "business": "business", "economy": "business", "finance": "business",
            "financial": "business", "money": "business", "markets": "business",
            "stock-market": "business", "companies": "business", "company": "business",
            "corporate": "business", "industry": "business", "trade": "business",
            "commercial": "business", "us": "business", "uk": "business",
            "us-news": "business", "uk-news": "business", "world": "business",
            "politics": "business", "political": "business", "government": "business",
            "policy": "business", "law": "business", "legal": "business",
            "international": "business", "breaking": "business", "general": "business",
            "news": "business", "business-business": "business", "business-us": "business",
            
            // Science
            "science": "science", "research": "science", "space": "science",
            "astronomy": "science", "environment": "science", "environmental": "science",
            "climate": "science", "climate-change": "science", "nature": "science",
            "earth": "science", "physics": "science", "chemistry": "science",
            "biology": "science", "genetics": "science", "evolution": "science",
            "energy": "science", "renewable": "science", "weather": "science",
            "discovery": "science", "laboratory": "science", "scientific": "science",
            "tech-and-science": "science", "science-science": "science", "science-environment": "science",
            
            // Health
            "health": "health", "wellness": "health", "medical": "health",
            "medicine": "health", "mental-health": "health", "fitness": "health",
            "nutrition": "health", "diet": "health", "disease": "health",
            "psychology": "health", "therapy": "health", "treatment": "health",
            "healthcare": "health", "public-health": "health", "life-and-style": "health",
            "lifestyle": "health", "lifeandstyle": "health", "life": "health",
            "society": "health", "wellbeing": "health", "health-health": "health",
            
            // Sports
            "sports": "sports", "sport": "sports", "football": "sports",
            "soccer": "sports", "basketball": "sports", "tennis": "sports",
            "baseball": "sports", "cricket": "sports", "rugby": "sports",
            "golf": "sports", "hockey": "sports", "formula-one": "sports",
            "f1": "sports", "olympics": "sports", "athletics": "sports",
            "swimming": "sports", "cycling": "sports", "boxing": "sports",
            "mma": "sports", "ufc": "sports", "racing": "sports",
            "motorsport": "sports", "skiing": "sports", "sports-sports": "sports",
            
            // Entertainment
            "entertainment": "entertainment", "arts": "entertainment", "culture": "entertainment",
            "arts-and-culture": "entertainment", "artanddesign": "entertainment",
            "books": "entertainment", "film": "entertainment", "movies": "entertainment",
            "music": "entertainment", "television": "entertainment", "tv": "entertainment",
            "streaming": "entertainment", "celebrity": "entertainment", "celebrities": "entertainment",
            "fashion": "entertainment", "style": "entertainment", "design": "entertainment",
            "photography": "entertainment", "gaming": "entertainment", "games": "entertainment",
            "theater": "entertainment", "theatre": "entertainment", "stage": "entertainment",
            "radio": "entertainment", "media": "entertainment", "social-media": "entertainment",
            "hollywood": "entertainment", "bollywood": "entertainment", "festival": "entertainment",
            "events": "entertainment", "gossip": "entertainment", "travel": "entertainment",
            "food": "entertainment", "restaurant": "entertainment", "recipes": "entertainment",
            "tv-and-radio": "entertainment", "culture-culture": "entertainment",
            "entertainment-entertainment": "entertainment",
        ]
        
        // If we reach here, no duplicates exist
        XCTAssertFalse(mappings.isEmpty, "Category mappings should not be empty")
        print("✅ Category mappings loaded successfully with \(mappings.count) entries")
    }
    
    func testAuthorityScoresNoDuplicates() {
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
        ]
        
        XCTAssertFalse(authorityScores.isEmpty, "Authority scores should not be empty")
        print("✅ Authority scores loaded successfully with \(authorityScores.count) entries")
    }
}
