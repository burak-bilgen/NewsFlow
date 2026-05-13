import SwiftUI

struct SourcesSkeletonView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                VStack(spacing: AppSpacing.sm) {
                    ShimmerLine(w: 280, h: 50)
                    ShimmerLine(w: 200, h: 3)
                    ShimmerLine(w: 180, h: 14)
                }
                .padding(.horizontal, AppSpacing.md)

                HStack(spacing: AppSpacing.sm) {
                    ForEach(0..<4, id: \.self) { _ in
                        ShimmerLine(w: 72, h: 36)
                    }
                }
                .padding(.horizontal, AppSpacing.md)

                ForEach(0..<3, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        ShimmerLine(w: 120, h: 20)
                        HStack(spacing: AppSpacing.md) {
                            ForEach(0..<3, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 8)
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
