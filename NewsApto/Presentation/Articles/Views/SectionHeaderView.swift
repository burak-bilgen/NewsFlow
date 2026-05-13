import SwiftUI

struct SectionHeaderView: View {
    let title: String

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Rectangle()
                .fill(AppPalette.accent)
                .frame(width: 5, height: 24)
                .clipShape(RoundedRectangle(cornerRadius: 2.5))

            Text(title)
                .font(.system(size: 20, weight: .black, design: .serif))
                .foregroundColor(AppPalette.textPrimary)

            Spacer()

            Capsule()
                .fill(AppPalette.accentMuted)
                .frame(width: 40, height: 4)
        }
    }
}

#if DEBUG
#if !CODEX_DISABLE_PREVIEWS
#Preview {
    SectionHeaderView(title: "Latest News")
        .padding()
}
#endif

#endif
