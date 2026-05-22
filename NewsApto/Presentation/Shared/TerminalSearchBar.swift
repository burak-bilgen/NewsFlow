import SwiftUI

struct TerminalSearchBar: View {
    @Binding var text: String
    var onSubmit: (String) -> Void

    @State private var cursorVisible = true
    @State private var blinkTimer: Timer?
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            Text(">")
                .font(AppTypography.caption.weight(.bold))
                .foregroundColor(AppPalette.accent)

            TextField("", text: $text)
                .font(AppTypography.caption)
                .foregroundColor(AppPalette.textPrimary)
                .focused($isFocused)
                .tint(AppPalette.accent)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .submitLabel(.search)
                .onSubmit { onSubmit(text) }
                .frame(minHeight: 18)

            if !text.isEmpty {
                Button {
                    text = ""; onSubmit("")
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppPalette.textTertiary)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Text("_")
                .font(AppTypography.caption.weight(.bold))
                .foregroundColor(cursorVisible ? AppPalette.accent : .clear)
                .frame(width: 6)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 34)
        .background(AppPalette.background)
        .overlay(Rectangle().stroke(AppPalette.accent.opacity(0.5), lineWidth: 1))
        .contentShape(Rectangle())
        .onTapGesture { isFocused = true }
        .onAppear {
            let t = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                cursorVisible.toggle()
            }
            blinkTimer = t
            RunLoop.current.add(t, forMode: .common)
        }
        .onDisappear {
            blinkTimer?.invalidate()
            blinkTimer = nil
        }
    }
}
