import Foundation
import Combine
@MainActor
final class FeedViewModel: ObservableObject {
    enum State: Equatable {
        case idle, loading, ready, empty
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var articles: [Article] = []
    @Published private(set) var savedArticleIDs: Set<String> = []
    @Published private(set) var isRefreshing = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMorePages = true
    @Published var selectedCategory: String? = nil
    @Published var searchQuery: String = ""

    var filteredArticles: [Article] {
        var result = articles
        if let category = selectedCategory {
            result = result.filter { matchesCategory($0, category) }
        }
        let query = searchQuery.trimmingCharacters(in: .whitespaces).lowercased()
        if !query.isEmpty {
            result = result.filter {
                $0.title.lowercased().contains(query) ||
                ($0.description?.lowercased().contains(query) ?? false) ||
                $0.sourceName.lowercased().contains(query)
            }
        }
        return result
    }

    private let aggregator: NewsAggregating
    private let readingListUseCase: ManageReadingListUseCaseProtocol
    private let pageSize: Int
    private var currentPage = 1

    init(
        aggregator: NewsAggregating,
        readingListUseCase: ManageReadingListUseCaseProtocol,
        pageSize: Int = 30
    ) {
        self.aggregator = aggregator
        self.readingListUseCase = readingListUseCase
        self.pageSize = pageSize
    }

    func loadIfNeeded() async {
        guard case .idle = state else { return }
        state = .loading
        await fetch()
    }

    func pullToRefresh() async {
        isRefreshing = true
        isLoadingMore = false
        currentPage = 1
        hasMorePages = true
        await fetch()
        isRefreshing = false
    }

    func loadMore() async {
        guard hasMorePages, !isLoadingMore else { return }
        isLoadingMore = true
        currentPage += 1
        await fetch()
        isLoadingMore = false
    }

    func prefetchIfNeeded(currentItem: Article) {
        let items = filteredArticles
        guard let index = items.firstIndex(where: { $0.id == currentItem.id }) else { return }
        let threshold = items.count - 5
        if index >= threshold {
            Task { await loadMore() }
        }
    }

    func isSaved(_ article: Article) -> Bool { savedArticleIDs.contains(article.id) }

    func toggleReadingList(for article: Article) async {
        if let result = try? await readingListUseCase.toggle(article) {
            if result { savedArticleIDs.insert(article.id) } else { savedArticleIDs.remove(article.id) }
        }
    }

    private func fetch() async {
        let result = await aggregator.fetchFeed(page: currentPage, pageSize: pageSize)
        async let savedIDs = readingListUseCase.savedArticleIDs()
        if currentPage > 1 {
            appendUnique(result.articles)
        } else {
            articles = result.articles
            if currentPage == 1 { Task { await SentinelNotificationService.shared.evaluateAndNotify(articles: result.articles) } }
        }
        hasMorePages = result.articles.count >= pageSize
        savedArticleIDs = await savedIDs
        state = articles.isEmpty ? .empty : .ready
    }

    private func appendUnique(_ newArticles: [Article]) {
        let existing = Set(articles.map(\.id))
        articles.append(contentsOf: newArticles.filter { !existing.contains($0.id) })
    }

    private func matchesCategory(_ article: Article, _ category: String) -> Bool {
        CategoryMatcher.matches(article, category: category)
    }
}

// MARK: - Category Matcher (Uses Article.category with NLP fallback)

enum CategoryMatcher {
    // Map external API categories to our standard categories
    // Supports: Guardian (sectionId), NYT (sectionName), NewsData (category[]), GNews (topic), HN (hardcoded)
    private static let categoryMappings: [String: String] = [
        // ========== TECHNOLOGY ==========
        "technology": "technology",
        "tech": "technology",
        "technology-science": "technology",
        "science-and-technology": "technology",
        "information-technology": "technology",
        "computers": "technology",
        "internet": "technology",
        "gadgets": "technology",
        "mobile": "technology",
        "telecommunications": "technology",
        "ai": "technology",
        "artificial-intelligence": "technology",
        "cyber-security": "technology",
        "cybersecurity": "technology",
        "programming": "technology",
        "software": "technology",
        "startups": "technology",
        "innovation": "technology",
        "scienceandtechnology": "technology",
        // NewsData specific
        "top": "technology", "technology-technology": "technology",
        
        // ========== BUSINESS ==========
        "business": "business",
        "economy": "business",
        "finance": "business",
        "financial": "business",
        "money": "business",
        "markets": "business",
        "stock-market": "business",
        "companies": "business",
        "company": "business",
        "corporate": "business",
        "industry": "business",
        "trade": "business",
        "commercial": "business",
        "us": "business", "uk": "business",  // Guardian US/UK news sections
        "us-news": "business",
        "uk-news": "business",
        "world": "business",
        "politics": "business",
        "political": "business",
        "government": "business",
        "policy": "business",
        "law": "business",
        "legal": "business",
        "international": "business",
        "breaking": "business",
        "general": "business",
        "news": "business",
        // NewsData specific
        "business-business": "business", "business-us": "business",
        
        // ========== SCIENCE ==========
        "science": "science",
        "research": "science",
        "space": "science",
        "astronomy": "science",
        "environment": "science",
        "environmental": "science",
        "climate": "science",
        "climate-change": "science",
        "nature": "science",
        "earth": "science",
        "physics": "science",
        "chemistry": "science",
        "biology": "science",
        "genetics": "science",
        "evolution": "science",
        "energy": "science",
        "renewable": "science",
        "weather": "science",
        "discovery": "science",
        "laboratory": "science",
        "scientific": "science",
        "tech-and-science": "science",
        // NewsData specific
        "science-science": "science", "science-environment": "science",
        
        // ========== HEALTH ==========
        "health": "health",
        "wellness": "health",
        "medical": "health",
        "medicine": "health",
        "mental-health": "health",
        "fitness": "health",
        "nutrition": "health",
        "diet": "health",
        "disease": "health",
        "psychology": "health",
        "therapy": "health",
        "treatment": "health",
        "healthcare": "health",
        "public-health": "health",
        "life-and-style": "health",
        "lifestyle": "health",
        "lifeandstyle": "health",
        "life": "health",
        "society": "health",
        "wellbeing": "health",
        // NewsData specific
        "health-health": "health",
        
        // ========== SPORTS ==========
        "sports": "sports",
        "sport": "sports",
        "football": "sports",
        "soccer": "sports",
        "basketball": "sports",
        "tennis": "sports",
        "baseball": "sports",
        "cricket": "sports",
        "rugby": "sports",
        "golf": "sports",
        "hockey": "sports",
        "formula-one": "sports",
        "f1": "sports",
        "olympics": "sports",
        "athletics": "sports",
        "swimming": "sports",
        "cycling": "sports",
        "boxing": "sports",
        "mma": "sports",
        "ufc": "sports",
        "racing": "sports",
        "motorsport": "sports",
        "skiing": "sports",
        // NewsData specific
        "sports-sports": "sports",
        
        // ========== ENTERTAINMENT ==========
        "entertainment": "entertainment",
        "arts": "entertainment",
        "culture": "entertainment",
        "arts-and-culture": "entertainment",
        "artanddesign": "entertainment",
        "books": "entertainment",
        "film": "entertainment",
        "movies": "entertainment",
        "music": "entertainment",
        "television": "entertainment",
        "tv": "entertainment",
        "streaming": "entertainment",
        "celebrity": "entertainment",
        "celebrities": "entertainment",
        "fashion": "entertainment",
        "style": "entertainment",
        "design": "entertainment",
        "photography": "entertainment",
        "gaming": "entertainment",
        "games": "entertainment",
        "theater": "entertainment",
        "theatre": "entertainment",
        "stage": "entertainment",
        "radio": "entertainment",
        "media": "entertainment",
        "social-media": "entertainment",
        "hollywood": "entertainment",
        "bollywood": "entertainment",
        "festival": "entertainment",
        "events": "entertainment",
        "gossip": "entertainment",
        "travel": "entertainment",
        "food": "entertainment",
        "restaurant": "entertainment",
        "recipes": "entertainment",
        "tv-and-radio": "entertainment",
        "culture-culture": "entertainment",
        "lifeandstyle": "entertainment",
        // NewsData specific
        "entertainment-entertainment": "entertainment",
    ]
    
    // Enhanced fallback keyword matching with more comprehensive terms
    private static let keywords: [String: [String]] = [
        "technology": [
            "tech", "technology", "artificial intelligence", "ai", "machine learning", "ml",
            "digital", "computer", "software", "hardware", "app", "apps", "application",
            "apple", "google", "microsoft", "amazon", "meta", "facebook", "twitter", "x",
            "crypto", "cryptocurrency", "bitcoin", "ethereum", "blockchain",
            "quantum", "quantum computing", "startup", "startups",
            "cybersecurity", "cyber security", "hacking", "hack", "breach",
            "algorithm", "algorithms", "data", "big data", "database",
            "smartphone", "phone", "mobile", "device", "gadget",
            "cloud", "cloud computing", "saas", "software as a service",
            "robot", "robotics", "automation", "automated", "drone", "drones",
            "semiconductor", "chip", "processor", "cpu", "gpu",
            "internet", "web", "online", "digital transformation",
            "5g", "wifi", "network", "telecommunications",
            "vr", "virtual reality", "ar", "augmented reality", "metaverse",
            "programming", "coding", "developer", "development", "api",
            "electric vehicle", "ev", "tesla", "battery", "renewable energy"
        ],
        "business": [
            "market", "markets", "stock", "stocks", "stock market", "exchange",
            "economy", "economic", "economics", "gdp", "inflation", "recession",
            "finance", "financial", "bank", "banking", "banks", "investment", "investing",
            "trade", "trading", "commerce", "commercial",
            "merger", "acquisition", "mergers and acquisitions", "m&a",
            "earnings", "revenue", "profit", "profits", "loss", "revenues",
            "corporate", "corporation", "company", "companies", "firm",
            "ceo", "cfo", "executive", "executives", "management",
            "shareholder", "shareholders", "investor", "investors",
            "ipo", "public offering", "valuation", "valued",
            "startup funding", "venture capital", "vc", "private equity",
            "deal", "deals", "contract", "contracts", "agreement",
            "tax", "taxes", "tariff", "tariffs", "regulation", "regulatory",
            "central bank", "federal reserve", "fed", "interest rate",
            "employment", "unemployment", "jobs", "job", "hiring", "layoff", "layoffs",
            "supply chain", "logistics", "shipping", "transport",
            "oil", "gas", "energy price", "commodity", "commodities",
            "real estate", "property", "housing", "mortgage",
            "manufacturing", "industry", "industrial", "production",
            "retail", "sales", "consumer", "consumption",
            "global trade", "international trade", "import", "export",
            "brexit", "eu", "european union", "trade war"
        ],
        "science": [
            "science", "scientific", "research", "researchers", "study", "studies",
            "space", "nasa", "spacex", "rocket", "satellite", "mars", "moon",
            "astronomy", "planet", "planets", "galaxy", "universe",
            "climate change", "global warming", "carbon", "emissions", "greenhouse",
            "environment", "environmental", "ecology", "ecosystem", "biodiversity",
            "nature", "natural", "wildlife", "animal", "animals", "species",
            "physics", "chemistry", "biology", "biological", "genetics", "gene", "genes", "dna", "rna",
            "evolution", "evolutionary", "natural selection",
            "laboratory", "lab", "experiment", "experimental",
            "discovery", "discoveries", "breakthrough", "finding", "findings",
            "renewable energy", "solar", "wind power", "hydroelectric", "nuclear",
            "material", "materials", "nanotechnology", "nano",
            "quantum physics", "particle physics", "theoretical physics",
            "archaeology", "archaeological", "fossil", "fossils",
            "ocean", "marine", "deep sea", "arctic", "antarctic",
            "weather", "forecast", "hurricane", "tornado", "storm", "earthquake",
            "volcano", "volcanic", "tsunami", "natural disaster",
            "medicine", "medical research", "clinical trial"
        ],
        "health": [
            "health", "healthy", "healthcare", "medical", "medical care",
            "medicine", "medication", "drug", "drugs", "pharmaceutical", "pharmacy",
            "hospital", "hospitals", "clinic", "doctor", "doctors", "physician", "physicians",
            "nurse", "nursing", "patient", "patients", "treatment", "treatments",
            "vaccine", "vaccines", "vaccination", "immunization",
            "mental health", "mental illness", "depression", "anxiety", "stress",
            "therapy", "therapist", "psychology", "psychological", "psychiatry",
            "disease", "diseases", "disorder", "disorders", "condition",
            "cancer", "tumor", "diabetes", "heart disease", "stroke",
            "pandemic", "epidemic", "outbreak", "virus", "viral", "infection",
            "covid", "coronavirus", "flu", "influenza",
            "wellness", "wellbeing", "self-care", "mindfulness", "meditation",
            "fitness", "exercise", "workout", "gym", "training",
            "nutrition", "diet", "healthy eating", "weight loss", "obesity",
            "sleep", "insomnia", "aging", "longevity",
            "surgery", "surgical", "operation", "transplant",
            "symptom", "symptoms", "diagnosis", "diagnostic",
            "public health", "health policy", "health insurance",
            "life expectancy", "mortality", "death rate"
        ],
        "sports": [
            "sport", "sports", "game", "games", "match", "matches", "competition",
            "team", "teams", "player", "players", "athlete", "athletes",
            "league", "leagues", "division", "conference", "championship",
            "football", "soccer", "premier league", "la liga", "bundesliga", "serie a",
            "nfl", "ncaa", "super bowl", "world cup",
            "basketball", "nba", "ncaa basketball", "final four", "march madness",
            "baseball", "mlb", "world series", "softball",
            "tennis", "grand slam", "wimbledon", "us open", "french open", "australian open",
            "golf", "pga", "masters", "open championship",
            "cricket", "ipl", "test cricket", "t20", "ashes",
            "rugby", "six nations", "rugby world cup", "nrl",
            "formula one", "f1", "grand prix", "racing", "motorsport", "nascar",
            "hockey", "nhl", "ice hockey", "field hockey",
            "olympics", "olympic", "olympic games", "paralympics",
            "athletics", "track and field", "marathon", "running", "sprinter",
            "swimming", "gymnastics", "boxing", "mma", "ufc", "wrestling",
            "cycling", "tour de france", "giro d'italia", "vuelta",
            "skiing", "snowboarding", "winter sports", "x games",
            "esports", "gaming competition",
            "score", "scored", "goal", "touchdown", "home run", "victory", "defeat",
            "coach", "coaching", "manager", "referee", "umpire",
            "transfer", "contract", "salary", "injury", "injured",
            "stadium", "arena", "venue", "crowd", "fans"
        ],
        "entertainment": [
            "entertainment", "entertain", "showbiz", "show business",
            "movie", "movies", "film", "films", "cinema", "cinematic",
            "actor", "actors", "actress", "actresses", "celebrity", "celebrities", "star", "stars",
            "director", "directors", "producer", "producers", "filmmaker",
            "hollywood", "bollywood", "nollywood", "blockbuster", "box office",
            "premiere", "debut", "release", "screening",
            "award", "awards", "oscar", "oscars", "emmy", "emmys", "grammy", "grammys", "golden globe",
            "bafta", "festival", "cannes", "sundance", "tiff", "venice film festival",
            "music", "musician", "musicians", "album", "albums", "single", "song", "songs",
            "singer", "singers", "band", "bands", "artist", "artists", "rapper", "rappers",
            "concert", "concert tour", "live performance", "gig", "festival",
            "television", "tv", "tv show", "tv series", "show", "shows", "series",
            "netflix", "streaming", "stream", "platform", "platforms", "episode", "season",
            "reality tv", "reality show", "talent show", "documentary",
            "theater", "theatre", "broadway", "west end", "play", "musical", "stage",
            "book", "books", "novel", "novels", "author", "authors", "writer", "writers",
            "bestseller", "publishing", "literature", "literary",
            "art", "arts", "artist", "artwork", "painting", "sculpture", "gallery", "museum",
            "culture", "cultural", "fashion", "style", "trend", "trends",
            "design", "designer", "photography", "photo", "photos",
            "gaming", "game", "games", "gamer", "gamers", "esports",
            "social media", "influencer", "viral", "trending", "meme",
            "gossip", "rumor", "scandal", "controversy", "relationship", "breakup", "wedding",
            "travel", "tourism", "vacation", "holiday", "destination",
            "food", "foodie", "restaurant", "dining", "chef", "cooking", "recipe", "recipes",
            "lifestyle", "life style", "home", "decor", "garden",
            "podcast", "podcasts", "radio", "broadcast", "media"
        ]
    ]

    static func matches(_ article: Article, category: String) -> Bool {
        // PRIORITY 1: Use API-provided category if available
        if let articleCategory = article.category?.lowercased() {
            // Check if API category maps directly to our category
            if let mappedCategory = categoryMappings[articleCategory] {
                // If mapping matches the requested category, use it
                if mappedCategory == category {
                    return true
                }
                // API has a specific category that doesn't match requested category
                // Don't guess with keywords - trust the API categorization
                return false
            } else if articleCategory == category {
                // Direct match without mapping needed
                return true
            }
            // API category doesn't match any known mapping
            // Fall through to keyword matching as last resort
        }
        
        // PRIORITY 2: Only use keyword matching when API provides NO category
        guard let categoryKeywords = keywords[category] else { return true }
        let text = (article.title + " " + (article.description ?? "") + " " + article.sourceName).lowercased()
        return categoryKeywords.contains { text.contains($0) }
    }
}
