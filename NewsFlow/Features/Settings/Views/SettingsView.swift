import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                ForEach(AppTheme.allCases) { theme in
                    ThemeRow(theme: theme, isSelected: themeManager.currentTheme == theme) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            themeManager.setTheme(theme)
                        }
                        Haptic.light()
                    }
                }
            } header: {
                Text(L10n.text("settings.appearance"))
                    .font(.system(size: 13, weight: .bold))
                    .textCase(.uppercase)
            }

            Section {
                ForEach(AppLanguage.allCases) { language in
                    LanguageRow(
                        language: language,
                        isSelected: languageManager.currentLanguage == language
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            languageManager.setLanguage(language)
                        }
                        Haptic.light()
                    }
                }
            } header: {
                Text(L10n.text("settings.language"))
                    .font(.system(size: 13, weight: .bold))
                    .textCase(.uppercase)
            }

            Section {
                HStack {
                    Label(L10n.text("settings.version"), systemImage: "number")
                        .font(.subheadline)
                    Spacer()
                    Text(appVersion)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                }

                HStack {
                    Label(L10n.text("settings.build"), systemImage: "hammer")
                        .font(.subheadline)
                    Spacer()
                    Text(appBuild)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                }
            } header: {
                Text(L10n.text("settings.about"))
                    .font(.system(size: 13, weight: .bold))
                    .textCase(.uppercase)
            }
        }
        .listStyle(.insetGrouped)
                .navigationTitle(L10n.text("settings.title"))
        .navigationBarTitleDisplayMode(.large)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    NavigationView {
        SettingsView()
            .environmentObject(ThemeManager())
            .environmentObject(LanguageManager())
    }
}
#endif
