import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    @AppStorage("digestFrequency") private var digestFrequency: DigestFrequency = .once

    var body: some View {
        List {
            // Notifications Section
            Section {
                Picker(selection: $digestFrequency) {
                    ForEach(DigestFrequency.allCases, id: \.self) { freq in
                        Text(L10n.text(freq.localizedKey))
                            .tag(freq)
                    }
                } label: {
                    Label(L10n.text("notifications.digest.frequency"), systemImage: "bell.badge.fill")
                        .font(.subheadline)
                }

                Text(L10n.text("notifications.digest.description"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)

                if digestFrequency != .off {
                    Button {
                        Task { await requestNotificationPermission() }
                    } label: {
                        HStack {
                            Label(L10n.text("notifications.allow"), systemImage: "checkmark.circle")
                                .font(.subheadline)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                    }
                }
            } header: {
                HStack(spacing: 6) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 12))
                    Text(L10n.text("notifications.title"))
                        .font(.system(size: 13, weight: .bold))
                        .textCase(.uppercase)
                }
            } footer: {
                Text(L10n.text("notifications.digest.footer"))
                    .font(.caption2)
            }

            // Appearance Section
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

            // Language Section
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

            // About Section
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

    private func requestNotificationPermission() async {
        let granted = await DigestNotificationService.shared.requestAuthorization()
        if granted {
            Haptic.success()
            ToastManager.shared.show(
                L10n.text("notifications.permission.granted"),
                style: .success,
                duration: 2.0
            )
        } else {
            ToastManager.shared.show(
                L10n.text("notifications.permission.denied"),
                style: .warning,
                duration: 3.0
            )
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

#if DEBUG
#Preview {
    NavigationView {
        SettingsView()
            .environmentObject(ThemeManager())
            .environmentObject(LanguageManager())
    }
}
#endif
