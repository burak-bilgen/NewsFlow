import SwiftUI

struct SourcesSkeletonView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                VStack(spacing: AppSpacing.sm) {
                    ShimmerLine(width: 280, height: 50)
                    ShimmerLine(width: 200, height: 3)
                    ShimmerLine(width: 180, height: 14)
                }
                .padding(.horizontal, AppSpacing.md)

                HStack(spacing: AppSpacing.sm) {
                    ForEach(0..<4, id: \.self) { _ in
                        ShimmerLine(width: 72, height: 36)
                    }
                }
                .padding(.horizontal, AppSpacing.md)

                ForEach(0..<3, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        ShimmerLine(width: 120, height: 20)
                        HStack(spacing: AppSpacing.md) {
                            ForEach(0..<3, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: AppRadius.md)
                                    .fill(Color(.tertiarySystemFill))
                                    .frame(width: 120, height: 140)
                                    .modifier(ShimmerEffect())
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                }
            }
            .padding(.vertical, AppSpacing.lg)
        }
    }
}
