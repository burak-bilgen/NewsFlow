import SwiftUI
import UserNotifications

struct SettingsView: View {
    @State private var notificationsEnabled = false
    @State private var showingClearCacheAlert = false
    @State private var cacheSize = ""

    var body: some View {
        ZStack {
            AppPalette.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    header
                    sectionDivider
                    notificationsSection
                    sectionDivider
                    dataSection
                    sectionDivider
                    aboutSection
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
        }
        .statusBarHidden(true)
        .onAppear {
            checkNotificationStatus()
            updateCacheSize()
        }
        .alert(L10n.text("settings.clear_cache.alert"), isPresented: $showingClearCacheAlert) {
            Button(L10n.text("ok.button"), role: .cancel) {}
            Button(L10n.text("settings.clear"), role: .destructive) { clearCache() }
        } message: {
            Text("\(L10n.text("settings.clear_cache.message")) (\(cacheSize))")
        }
    }

    private var header: some View {
        HStack {
            Text(L10n.text("settings.title")).font(AppTypography.monoSmall).foregroundColor(AppPalette.accent)
            Spacer()
        }
        .padding(.top, 20).padding(.bottom, 4)
    }

    private var sectionDivider: some View {
        Rectangle().fill(AppPalette.dividerBorder).frame(height: 0.5).padding(.vertical, 8)
    }

    private var notificationsSection: some View {
        VStack(spacing: 12) {
            sectionHeader("settings.notifications")
            Toggle(isOn: $notificationsEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.text("settings.notifications.breaking")).font(AppTypography.body).foregroundColor(AppPalette.textPrimary)
                    Text(L10n.text("settings.notifications.description")).font(AppTypography.caption).foregroundColor(AppPalette.textTertiary)
                }
            }
            .toggleStyle(NotificationToggleStyle())
            .onChange(of: notificationsEnabled) { _, newValue in toggleNotifications(enabled: newValue) }
        }
        .padding(.vertical, 12)
    }

    private var dataSection: some View {
        VStack(spacing: 12) {
            sectionHeader("settings.data")
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showingClearCacheAlert = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.text("settings.clear_cache")).font(AppTypography.body).foregroundColor(AppPalette.textPrimary)
                        Text(L10n.text("settings.clear_cache.description")).font(AppTypography.caption).foregroundColor(AppPalette.textTertiary)
                    }
                    Spacer()
                    Text(cacheSize).font(AppTypography.monoTiny).foregroundColor(AppPalette.textTertiary)
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 12)
    }

    private var aboutSection: some View {
        VStack(spacing: 12) {
            sectionHeader("settings.about")
            aboutRow(label: "settings.version", value: versionString)
            aboutRow(label: "settings.build", value: buildString)
            aboutRow(label: "settings.sources", value: "6 APIs")
            Text(L10n.text("settings.disclaimer")).font(AppTypography.monoTiny).foregroundColor(AppPalette.textTertiary).padding(.top, 8)
        }
        .padding(.vertical, 12)
    }

    private func sectionHeader(_ key: String) -> some View {
        HStack {
            Text(L10n.text(key)).font(AppTypography.monoSmall).foregroundColor(AppPalette.accent.opacity(0.7))
            Spacer()
        }
    }

    private func aboutRow(label: String, value: String) -> some View {
        HStack {
            Text(L10n.text(label)).font(AppTypography.body).foregroundColor(AppPalette.textSecondary)
            Spacer()
            Text(value).font(AppTypography.monoTiny).foregroundColor(AppPalette.textPrimary)
        }
        .padding(.vertical, 4)
    }

    private var versionString: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var buildString: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { notificationsEnabled = settings.authorizationStatus == .authorized }
        }
    }

    private func toggleNotifications(enabled: Bool) {
        if enabled {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
                DispatchQueue.main.async { notificationsEnabled = granted }
            }
        } else {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            notificationsEnabled = false
        }
    }

    private func updateCacheSize() {
        guard let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }
        let dirs = [cachesDir.appendingPathComponent("NewsAptoImageCache"), cachesDir.appendingPathComponent("NewsAptoCache")]
        var total = 0
        for dir in dirs {
            guard let enumerator = FileManager.default.enumerator(at: dir, includingPropertiesForKeys: [.fileSizeKey]) else { continue }
            for case let file as URL in enumerator {
                total += (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            }
        }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        cacheSize = formatter.string(fromByteCount: Int64(total))
    }

    private func clearCache() {
        Task {
            await ImageCacheAdapter.clearShared()
            updateCacheSize()
        }
    }
}

private struct NotificationToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? AppPalette.accent : AppPalette.textTertiary.opacity(0.3))
                .frame(width: 50, height: 30)
                .overlay(Circle().fill(configuration.isOn ? .black : AppPalette.textTertiary).padding(3).offset(x: configuration.isOn ? 10 : -10))
                .onTapGesture { configuration.isOn.toggle() }
        }
    }
}
