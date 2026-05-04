import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        List {
            Section(header: Text("Appearance").textCase(.uppercase)) {
                ForEach(AppTheme.allCases) { theme in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            themeManager.setTheme(theme)
                        }
                    } label: {
                        HStack {
                            Text(theme.displayName)
                                .foregroundColor(.primary)

                            Spacer()

                            if themeManager.currentTheme == theme {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppPalette.primaryRed)
                                    .font(.body.weight(.semibold))
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .listStyle(.insetGrouped)
    }
}
