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
                ShimmerLine(width: 200, height: 16)
                ShimmerLine(width: 180, height: 16)
                ShimmerLine(width: 120, height: 16)

                Spacer(minLength: 0)

                ShimmerLine(width: 80, height: 12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
                .frame(maxWidth: .infinity, minHeight: 220, idealHeight: 220, maxHeight: 220)
                .modifier(ShimmerEffect())

            ShimmerLine(width: 260, height: 22)
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
