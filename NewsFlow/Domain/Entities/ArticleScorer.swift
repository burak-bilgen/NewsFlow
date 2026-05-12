import Foundation

struct ScoredArticle: Identifiable, Equatable {
    let article: Article
    let score: Int

    var id: String { article.id }

    static func == (lhs: ScoredArticle, rhs: ScoredArticle) -> Bool {
        lhs.article.id == rhs.article.id
    }
}

struct SmartArticleScorer {
    private let now: Date

    init(now: Date = Date()) {
        self.now = now
    }

    func score(_ articles: [Article]) -> [ScoredArticle] {
        articles.map { article in
            let score = recencyScore(article) + contentScore(article) + titleScore(article)
            return ScoredArticle(article: article, score: score)
        }
    }

    func sortAndDeduplicate(_ articles: [Article]) -> [Article] {
        var seen = Set<String>()
        let scored = score(articles).sorted { $0.score > $1.score }
        var result: [Article] = []
        for item in scored {
            guard !seen.contains(item.article.id) else { continue }
            seen.insert(item.article.id)
            result.append(item.article)
        }
        return result
    }

    private func recencyScore(_ article: Article) -> Int {
        guard let publishedAt = article.publishedAt else { return 0 }
        let hoursAgo = now.timeIntervalSince(publishedAt) / 3600
        switch hoursAgo {
        case ..<1:   return 40
        case ..<3:   return 35
        case ..<6:   return 30
        case ..<12:  return 25
        case ..<24:  return 20
        case ..<48:  return 12
        case ..<72:  return 6
        default:     return 2
        }
    }

    private func contentScore(_ article: Article) -> Int {
        var score = 0
        if article.imageURL != nil { score += 15 }
        if let desc = article.description, !desc.isEmpty {
            score += min(desc.count / 20, 10)
        }
        if let snippet = article.contentSnippet, !snippet.isEmpty {
            score += 5
        }
        return score
    }

    private func titleScore(_ article: Article) -> Int {
        let title = article.title
        guard !title.isEmpty else { return 0 }
        let length = title.count
        if length < 20 { return 3 }
        if length < 40 { return 7 }
        if length < 80 { return 12 }
        return 15
    }
}
