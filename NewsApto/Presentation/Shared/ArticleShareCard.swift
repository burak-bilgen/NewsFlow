import SwiftUI

struct ArticleShareCard: View {
    let article: Article
    let sourceName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(sourceName.uppercased())
                    .font(AppTypography.small)
                    .foregroundColor(AppPalette.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppPalette.accentMuted)
                    .clipShape(Capsule())

                Text(article.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .lineSpacing(4)
                    .lineLimit(4)

                if let description = article.description {
                    Text(description)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                }

                HStack(spacing: AppSpacing.sm) {
                    Text(article.displayDate)
                        .font(AppTypography.caption)
                        .foregroundColor(.white.opacity(0.5))
                    if article.estimatedReadingMinutes > 0 {
                        Circle()
                            .fill(.white.opacity(0.3))
                            .frame(width: 3, height: 3)
                        Text(article.readingTimeDisplay)
                            .font(AppTypography.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .padding(AppSpacing.lg)
            .background(
                LinearGradient(
                    colors: [.black.opacity(0.85), .black.opacity(0.6), .clear],
                    startPoint: .bottom, endPoint: .top
                )
            )
        }
        .frame(width: 320, height: 400)
        .background(
            Group {
                if let url = article.imageURL {
                    ArticleImageView(url: url)
                        .frame(width: 320, height: 400)
                } else {
                    AppPalette.accent
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

extension View {
    @MainActor
    func renderAsImage(size: CGSize = CGSize(width: 320, height: 400)) -> UIImage? {
        let controller = UIHostingController(rootView: self)
        controller.view.frame = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}
