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
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.tertiarySystemFill))
                .frame(width: 100, height: 100)
                .modifier(ShimmerEffect())

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                ShimmerLine(w: 200, h: 16)
                ShimmerLine(w: 180, h: 16)
                ShimmerLine(w: 120, h: 16)

                Spacer(minLength: 0)

                ShimmerLine(w: 80, h: 12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, AppSpacing.xs)
        }
        .padding(AppSpacing.md)
        .background(AppPalette.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct ArticleHeroSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.tertiarySystemFill))
                .frame(maxWidth: .infinity, minHeight: 220, idealHeight: 220, maxHeight: 220)
                .modifier(ShimmerEffect())

            ShimmerLine(w: 260, h: 22)
            ShimmerLine(w: 200, h: 22)
            ShimmerLine(w: 100, h: 12)
        }
        .padding(AppSpacing.md)
        .background(AppPalette.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#if DEBUG
#if !CODEX_DISABLE_PREVIEWS
#Preview {
    ArticlesSkeletonView()
}
#endif

#endif
