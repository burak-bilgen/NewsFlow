import WidgetKit
import SwiftUI

// MARK: - NewsFlow Widget

@main
struct NewsFlowWidgetBundle: WidgetBundle {
    var body: some Widget {
        NewsFlowWidget()
    }
}

struct NewsFlowWidget: Widget {
    let kind: String = "NewsFlowWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NewsProvider()) { entry in
            NewsFlowWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("NewsFlow Headlines")
        .description("Stay updated with the latest top headlines.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}
