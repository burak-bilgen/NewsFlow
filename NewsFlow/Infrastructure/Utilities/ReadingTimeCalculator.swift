import Foundation

struct ReadingTimeCalculator {
    static func estimate(for text: String) -> Int {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return 0 }
        let wordsPerMinute = 200
        let wordCount = text.split(separator: " ").count
        let minutes = max(1, Int(ceil(Double(wordCount) / Double(wordsPerMinute))))
        return minutes
    }

    static func estimate(for article: Article) -> Int {
        let texts = [article.title, article.description, article.contentSnippet].compactMap { $0 }
        return estimate(for: texts.joined(separator: " "))
    }

    static func displayString(for minutes: Int) -> String {
        if minutes < 1 { return "<1 min" }
        return "\(minutes) min read"
    }
}

extension Article {
    var estimatedReadingMinutes: Int {
        ReadingTimeCalculator.estimate(for: self)
    }

    var readingTimeDisplay: String {
        ReadingTimeCalculator.displayString(for: estimatedReadingMinutes)
    }
}
