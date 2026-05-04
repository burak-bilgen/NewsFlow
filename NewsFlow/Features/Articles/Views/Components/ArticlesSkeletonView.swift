import SwiftUI

struct ArticlesSkeletonView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.lg) {
                ArticleHeroSkeleton()
                    .padding(.horizontal, AppSpacing.md)

                ForEach(0..<3, id: \.self) { _ in
                    ArticleRowSkeleton()
                        .padding(.horizontal, AppSpacing.md)
                }
            }
            .padding(.vertical, AppSpacing.lg)
        }
    }
}

struct ArticleRowSkeleton: View {
    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(Color(.tertiarySystemFill))
                .frame(width: 100, height: 100)
                .modifier(ShimmerEffect())

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                ShimmerLine(width: .infinity, height: 16)
                ShimmerLine(width: .infinity, height: 16)
                ShimmerLine(width: 160, height: 16)

                Spacer(minLength: 0)

                ShimmerLine(width: 80, height: 12)
            }
            .padding(.vertical, AppSpacing.xs)
        }
        .padding(AppSpacing.md)
        .background(AppPalette.elevatedBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
    }
}

struct ArticleHeroSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            RoundedRectangle(cornerRadius: AppRadius.xl)
                .fill(Color(.tertiarySystemFill))
                .frame(height: 220)
                .modifier(ShimmerEffect())

            ShimmerLine(width: .infinity, height: 22)
            ShimmerLine(width: 200, height: 22)
            ShimmerLine(width: 100, height: 12)
        }
        .padding(AppSpacing.md)
        .background(AppPalette.elevatedBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
    }
}

#if DEBUG
#Preview {
    ArticlesSkeletonView()
}
#endif
