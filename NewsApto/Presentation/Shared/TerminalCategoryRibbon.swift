import SwiftUI

struct TerminalCategoryRibbon: View {
    @Binding var selected: String?

    let categories: [(key: String, label: String)] = [
        ("all", "ALL"), ("technology", "TECH"), ("business", "BUSINESS"),
        ("science", "SCIENCE"), ("health", "HEALTH"),
        ("sports", "SPORTS"), ("entertainment", "ENTERTAINMENT"),
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.key) { cat in
                    let isActive = selected == cat.key || (selected == nil && cat.key == "all")
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selected = cat.key == "all" ? nil : cat.key
                    } label: {
                        Text("[/ \(cat.label)]")
                            .font(AppTypography.body.weight(isActive ? .bold : .regular))
                            .foregroundColor(isActive ? .black : AppPalette.accent)
                            .padding(.horizontal, 20)
                            .frame(minHeight: 48)
                            .frame(maxWidth: .infinity)
                            .background(isActive ? AppPalette.accent : AppPalette.background)
                            .overlay(Rectangle().stroke(AppPalette.accent, lineWidth: 1))
                    }
                    .buttonStyle(.borderless)
                    .frame(minHeight: 48)
                    .contentShape(Rectangle())
                    .glowPulse(isActive: isActive)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(minHeight: 52)
        .background(AppPalette.background)
    }
}
