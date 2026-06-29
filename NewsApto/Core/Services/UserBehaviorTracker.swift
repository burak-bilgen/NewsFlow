import Foundation


actor UserBehaviorTracker {
    static let shared = UserBehaviorTracker()
    
    private var interactions: [ArticleInteraction] = []
    private let storageKey = "user_behavior_interactions"
    private var userProfile: UserPreferenceProfile = UserPreferenceProfile()
    
    struct ArticleInteraction: Codable, Sendable {
        let articleID: String
        let articleTitle: String
        let articleSource: String
        let action: InteractionType
        let timestamp: Date
        let duration: TimeInterval? // For read time
        let category: String?
        
        enum InteractionType: String, Codable {
            case tapped = "tapped"
            case saved = "saved"
            case shared = "shared"
            case dismissed = "dismissed"
            case scrolledPast = "scrolled_past"
            case readComplete = "read_complete"
            case timeSpent = "time_spent"
        }
    }
    
    struct UserPreferenceProfile: Codable, Sendable {
        var preferredCategories: [String: Double]
        var preferredSources: [String: Double]
        var readingTimePattern: ReadingTimePattern
        var contentDepth: ContentDepthPreference
        
        init(
            preferredCategories: [String: Double] = [:],
            preferredSources: [String: Double] = [:],
            readingTimePattern: ReadingTimePattern = .evening,
            contentDepth: ContentDepthPreference = .balanced
        ) {
            self.preferredCategories = preferredCategories
            self.preferredSources = preferredSources
            self.readingTimePattern = readingTimePattern
            self.contentDepth = contentDepth
        }
        
        enum ReadingTimePattern: String, Codable, Sendable {
            case morning = "Morning"
            case afternoon = "Afternoon"
            case evening = "Evening"
            case night = "Night"
        }
        
        enum ContentDepthPreference: String, Codable, Sendable {
            case quick = "Quick updates"
            case balanced = "Balanced"
            case deep = "Deep dives"
        }
    }
    
    private init() {
        Task {
            await loadFromStorage()
        }
    }
    
    
    func trackTap(article: Article) async {
        let interaction = ArticleInteraction(
            articleID: article.id,
            articleTitle: article.title,
            articleSource: article.sourceName,
            action: .tapped,
            timestamp: Date(),
            duration: nil,
            category: nil
        )
        await addInteraction(interaction)
        await updateProfile(for: article, action: .tapped)
    }
    
    func trackSave(article: Article) async {
        let interaction = ArticleInteraction(
            articleID: article.id,
            articleTitle: article.title,
            articleSource: article.sourceName,
            action: .saved,
            timestamp: Date(),
            duration: nil,
            category: nil
        )
        await addInteraction(interaction)
        await updateProfile(for: article, action: .saved)
    }
    
    func trackDismiss(article: Article) async {
        let interaction = ArticleInteraction(
            articleID: article.id,
            articleTitle: article.title,
            articleSource: article.sourceName,
            action: .dismissed,
            timestamp: Date(),
            duration: nil,
            category: nil
        )
        await addInteraction(interaction)
        await updateProfile(for: article, action: .dismissed)
    }
    
    func trackReadingTime(article: Article, duration: TimeInterval) async {
        let interaction = ArticleInteraction(
            articleID: article.id,
            articleTitle: article.title,
            articleSource: article.sourceName,
            action: .timeSpent,
            timestamp: Date(),
            duration: duration,
            category: nil
        )
        await addInteraction(interaction)
        
        if duration > 30 {
            await updateProfile(for: article, action: .readComplete)
        }
    }
    
    func trackScrollPast(article: Article) async {
        let interaction = ArticleInteraction(
            articleID: article.id,
            articleTitle: article.title,
            articleSource: article.sourceName,
            action: .scrolledPast,
            timestamp: Date(),
            duration: nil,
            category: nil
        )
        await addInteraction(interaction)
    }
    
    
    private func addInteraction(_ interaction: ArticleInteraction) async {
        interactions.append(interaction)
        
        if interactions.count > 1000 {
            interactions.removeFirst(interactions.count - 1000)
        }
        
        await saveToStorage()
    }
    
    private func updateProfile(for article: Article, action: ArticleInteraction.InteractionType) async {
        let source = article.sourceName
        
        switch action {
        case .tapped, .saved, .readComplete:
            let currentScore = userProfile.preferredSources[source, default: 0.5]
            userProfile.preferredSources[source] = min(1.0, currentScore + 0.05)
            
        case .dismissed, .scrolledPast:
            let currentScore = userProfile.preferredSources[source, default: 0.5]
            userProfile.preferredSources[source] = max(0.0, currentScore - 0.02)
            
        default:
            break
        }
    }
    
    
    func getUserProfile() async -> UserPreferenceProfile {
        return userProfile
    }
    
    func getTopPreferredSources(limit: Int = 5) async -> [(source: String, score: Double)] {
        return userProfile.preferredSources
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { (source: $0.key, score: $0.value) }
    }
    
    
    private func saveToStorage() async {
        if let data = try? JSONEncoder().encode(interactions) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
        if let profileData = try? JSONEncoder().encode(userProfile) {
            UserDefaults.standard.set(profileData, forKey: "user_preference_profile")
        }
    }
    
    private func loadFromStorage() async {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let loaded = try? JSONDecoder().decode([ArticleInteraction].self, from: data) {
            interactions = loaded
        }
        if let profileData = UserDefaults.standard.data(forKey: "user_preference_profile"),
           let profile = try? JSONDecoder().decode(UserPreferenceProfile.self, from: profileData) {
            userProfile = profile
        }
    }
    
    
    func getReadingStats() async -> (totalArticles: Int, totalReadTime: TimeInterval, avgReadTime: TimeInterval) {
        let readInteractions = interactions.filter { $0.action == .timeSpent }
        let totalTime = readInteractions.compactMap { $0.duration }.reduce(0, +)
        let count = readInteractions.count
        let avg = count > 0 ? totalTime / Double(count) : 0
        return (count, totalTime, avg)
    }
    
    func getMostActiveHours() async -> [Int] {
        var hourCounts: [Int: Int] = [:]
        for interaction in interactions {
            let hour = Calendar.current.component(.hour, from: interaction.timestamp)
            hourCounts[hour, default: 0] += 1
        }
        return hourCounts.sorted { $0.value > $1.value }.prefix(3).map { $0.key }
    }
    
    func reset() async {
        interactions.removeAll()
        userProfile = UserPreferenceProfile()
        UserDefaults.standard.removeObject(forKey: storageKey)
        UserDefaults.standard.removeObject(forKey: "user_preference_profile")
    }
}
