import SwiftUI

struct TerminalSearchBar: View {
    @Binding var text: String
    var onSubmit: (String) -> Void

    @State private var cursorVisible = true
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(">")
                .font(AppTypography.body.weight(.bold))
                .foregroundColor(AppPalette.accent)

            TextField("", text: $text)
                .font(AppTypography.body)
                .foregroundColor(AppPalette.textPrimary)
                .focused($isFocused)
                .tint(AppPalette.accent)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .submitLabel(.search)
                .onSubmit { onSubmit(text) }
                .frame(minHeight: 24)

            if !text.isEmpty {
                Button {
                    text = ""; onSubmit("")
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppPalette.textTertiary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Text("_")
                .font(AppTypography.body.weight(.bold))
                .foregroundColor(cursorVisible ? AppPalette.accent : .clear)
                .frame(width: 8)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 50)
        .background(AppPalette.background)
        .overlay(Rectangle().stroke(AppPalette.accent.opacity(0.5), lineWidth: 1))
        .contentShape(Rectangle())
        .onTapGesture { isFocused = true }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                cursorVisible.toggle()
            }
        }
    }
}
