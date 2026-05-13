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
    
    // Using computed property instead of static let to avoid runtime dictionary literal crash
    private static var categoryMappings: [String: String] {
        var mappings: [String: String] = [:]
        
        // ========== TECHNOLOGY ==========
        mappings["technology"] = "technology"
        mappings["tech"] = "technology"
        mappings["technology-science"] = "technology"
        mappings["science-and-technology"] = "technology"
        mappings["information-technology"] = "technology"
        mappings["computers"] = "technology"
        mappings["internet"] = "technology"
        mappings["gadgets"] = "technology"
        mappings["mobile"] = "technology"
        mappings["telecommunications"] = "technology"
        mappings["ai"] = "technology"
        mappings["artificial-intelligence"] = "technology"
        mappings["cyber-security"] = "technology"
        mappings["cybersecurity"] = "technology"
        mappings["programming"] = "technology"
        mappings["software"] = "technology"
        mappings["startups"] = "technology"
        mappings["innovation"] = "technology"
        mappings["scienceandtechnology"] = "technology"
        // NewsData specific
        mappings["top"] = "technology"
        mappings["technology-technology"] = "technology"
        
        // ========== BUSINESS ==========
        mappings["business"] = "business"
        mappings["economy"] = "business"
        mappings["finance"] = "business"
        mappings["financial"] = "business"
        mappings["money"] = "business"
        mappings["markets"] = "business"
        mappings["stock-market"] = "business"
        mappings["companies"] = "business"
        mappings["company"] = "business"
        mappings["corporate"] = "business"
        mappings["industry"] = "business"
        mappings["trade"] = "business"
        mappings["commercial"] = "business"
        mappings["us"] = "business"
        mappings["uk"] = "business"
        mappings["us-news"] = "business"
        mappings["uk-news"] = "business"
        mappings["world"] = "business"
        mappings["politics"] = "business"
        mappings["political"] = "business"
        mappings["government"] = "business"
        mappings["policy"] = "business"
        mappings["law"] = "business"
        mappings["legal"] = "business"
        mappings["international"] = "business"
        mappings["breaking"] = "business"
        mappings["general"] = "business"
        mappings["news"] = "business"
        // NewsData specific
        mappings["business-business"] = "business"
        mappings["business-us"] = "business"
        
        // ========== SCIENCE ==========
        mappings["science"] = "science"
        mappings["research"] = "science"
        mappings["space"] = "science"
        mappings["astronomy"] = "science"
        mappings["environment"] = "science"
        mappings["environmental"] = "science"
        mappings["climate"] = "science"
        mappings["climate-change"] = "science"
        mappings["nature"] = "science"
        mappings["earth"] = "science"
        mappings["physics"] = "science"
        mappings["chemistry"] = "science"
        mappings["biology"] = "science"
        mappings["genetics"] = "science"
        mappings["evolution"] = "science"
        mappings["energy"] = "science"
        mappings["renewable"] = "science"
        mappings["weather"] = "science"
        mappings["discovery"] = "science"
        mappings["laboratory"] = "science"
        mappings["scientific"] = "science"
        mappings["tech-and-science"] = "science"
        // NewsData specific
        mappings["science-science"] = "science"
        mappings["science-environment"] = "science"
        
        // ========== HEALTH ==========
        mappings["health"] = "health"
        mappings["wellness"] = "health"
        mappings["medical"] = "health"
        mappings["medicine"] = "health"
        mappings["mental-health"] = "health"
        mappings["fitness"] = "health"
        mappings["nutrition"] = "health"
        mappings["diet"] = "health"
        mappings["disease"] = "health"
        mappings["psychology"] = "health"
        mappings["therapy"] = "health"
        mappings["treatment"] = "health"
        mappings["healthcare"] = "health"
        mappings["public-health"] = "health"
        mappings["life-and-style"] = "health"
        mappings["lifestyle"] = "health"
        mappings["lifeandstyle"] = "health"
        mappings["life"] = "health"
        mappings["society"] = "health"
        mappings["wellbeing"] = "health"
        // NewsData specific
        mappings["health-health"] = "health"
        
        // ========== SPORTS ==========
        mappings["sports"] = "sports"
        mappings["sport"] = "sports"
        mappings["football"] = "sports"
        mappings["soccer"] = "sports"
        mappings["basketball"] = "sports"
        mappings["tennis"] = "sports"
        mappings["baseball"] = "sports"
        mappings["cricket"] = "sports"
        mappings["rugby"] = "sports"
        mappings["golf"] = "sports"
        mappings["hockey"] = "sports"
        mappings["formula-one"] = "sports"
        mappings["f1"] = "sports"
        mappings["olympics"] = "sports"
        mappings["athletics"] = "sports"
        mappings["swimming"] = "sports"
        mappings["cycling"] = "sports"
        mappings["boxing"] = "sports"
        mappings["mma"] = "sports"
        mappings["ufc"] = "sports"
        mappings["racing"] = "sports"
        mappings["motorsport"] = "sports"
        mappings["skiing"] = "sports"
        // NewsData specific
        mappings["sports-sports"] = "sports"
        
        // ========== ENTERTAINMENT ==========
        mappings["entertainment"] = "entertainment"
        mappings["arts"] = "entertainment"
        mappings["culture"] = "entertainment"
        mappings["arts-and-culture"] = "entertainment"
        mappings["artanddesign"] = "entertainment"
        mappings["books"] = "entertainment"
        mappings["film"] = "entertainment"
        mappings["movies"] = "entertainment"
        mappings["music"] = "entertainment"
        mappings["television"] = "entertainment"
        mappings["tv"] = "entertainment"
        mappings["streaming"] = "entertainment"
        mappings["celebrity"] = "entertainment"
        mappings["celebrities"] = "entertainment"
        mappings["fashion"] = "entertainment"
        mappings["style"] = "entertainment"
        mappings["design"] = "entertainment"
        mappings["photography"] = "entertainment"
        mappings["gaming"] = "entertainment"
        mappings["games"] = "entertainment"
        mappings["theater"] = "entertainment"
        mappings["theatre"] = "entertainment"
        mappings["stage"] = "entertainment"
        mappings["radio"] = "entertainment"
        mappings["media"] = "entertainment"
        mappings["social-media"] = "entertainment"
        mappings["hollywood"] = "entertainment"
        mappings["bollywood"] = "entertainment"
        mappings["festival"] = "entertainment"
        mappings["events"] = "entertainment"
        mappings["gossip"] = "entertainment"
        mappings["travel"] = "entertainment"
        mappings["food"] = "entertainment"
        mappings["restaurant"] = "entertainment"
        mappings["recipes"] = "entertainment"
        mappings["tv-and-radio"] = "entertainment"
        mappings["culture-culture"] = "entertainment"
        mappings["lifeandstyle"] = "entertainment"
        // NewsData specific
        mappings["entertainment-entertainment"] = "entertainment"
        
        return mappings
    }
    
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
