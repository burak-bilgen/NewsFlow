import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            appHeaderSection

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
                Text("Appearance")
                    .font(.system(size: 13, weight: .bold))
                    .textCase(.uppercase)
            }

            Section {
                HStack {
                    Label("Version", systemImage: "number")
                        .font(.subheadline)
                    Spacer()
                    Text(appVersion)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                }

                HStack {
                    Label("Build", systemImage: "hammer")
                        .font(.subheadline)
                    Spacer()
                    Text(appBuild)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("About")
                    .font(.system(size: 13, weight: .bold))
                    .textCase(.uppercase)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }

    private var appHeaderSection: some View {
        Section {
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                        .fill(AppPalette.primaryRed)
                        .frame(width: 64, height: 64)
                        .shadow(color: AppPalette.primaryRed.opacity(0.3), radius: 12, x: 0, y: 6)

                    Image(systemName: "newspaper.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("NewsFlow")
                        .font(.system(size: 22, weight: .black, design: .serif))
                        .foregroundColor(AppPalette.textPrimary)

                    Text("Your daily news companion")
                        .font(.subheadline)
                        .foregroundColor(AppPalette.textSecondary)
                }

                Spacer()
            }
            .padding(.vertical, AppSpacing.sm)
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

// MARK: - Theme Row

private struct ThemeRow: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                themeIcon
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                            .fill(isSelected ? AppPalette.primaryRed.opacity(0.12) : Color(.tertiarySystemFill))
                    )

                Text(theme.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppPalette.primaryRed)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }

    @ViewBuilder
    private var themeIcon: some View {
        switch theme {
        case .light:
            Image(systemName: "sun.max.fill")
                .foregroundColor(.orange)
        case .dark:
            Image(systemName: "moon.fill")
                .foregroundColor(.indigo)
        case .system:
            Image(systemName: "circle.lefthalf.filled")
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    NavigationView {
        SettingsView()
            .environmentObject(ThemeManager.shared)
    }
}
#endif
