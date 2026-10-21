import AppKit
import Observation

@MainActor
@Observable
final class PrivacySettingsViewModel {
    struct IgnoredApp: Identifiable {
        let id: String
        let name: String
        let icon: NSImage?
    }

    let retentionOptions = HistoryRetention.allCases

    private(set) var ignoredApps: [IgnoredApp] = []
    var selectedAppID: String?
    var retention: HistoryRetention {
        didSet {
            guard retention != oldValue else { return }
            preferences.retention = retention
            pruneExpiredItemsUseCase.execute()
        }
    }
    var clearsHistoryOnQuit: Bool {
        didSet { preferences.clearsHistoryOnQuit = clearsHistoryOnQuit }
    }

    private let preferences: PreferencesStoring
    private let ignoredAppsProvider: IgnoredAppsProviding
    private let appInfo: AppInfoProviding
    private let pruneExpiredItemsUseCase: PruneExpiredItemsUseCase

    init(
        preferences: PreferencesStoring,
        ignoredApps: IgnoredAppsProviding,
        appInfo: AppInfoProviding,
        pruneExpiredItemsUseCase: PruneExpiredItemsUseCase
    ) {
        self.preferences = preferences
        self.ignoredAppsProvider = ignoredApps
        self.appInfo = appInfo
        self.pruneExpiredItemsUseCase = pruneExpiredItemsUseCase
        self.retention = preferences.retention
        self.clearsHistoryOnQuit = preferences.clearsHistoryOnQuit
        reloadIgnoredApps()
    }

    // MARK: - Ignored apps

    func addApp(bundleIdentifier: String) {
        ignoredAppsProvider.bundleIdentifiers.append(bundleIdentifier)
        reloadIgnoredApps()
        selectedAppID = bundleIdentifier
    }

    func removeSelectedApp() {
        guard let selectedAppID else { return }
        ignoredAppsProvider.bundleIdentifiers.removeAll { $0 == selectedAppID }
        self.selectedAppID = nil
        reloadIgnoredApps()
    }

    func restoreDefaultIgnoredApps() {
        ignoredAppsProvider.restoreDefaults()
        selectedAppID = nil
        reloadIgnoredApps()
    }

    private func reloadIgnoredApps() {
        ignoredApps = ignoredAppsProvider.bundleIdentifiers
            .map { id in
                let info = appInfo.appInfo(bundleIdentifier: id)
                return IgnoredApp(id: id, name: info.name, icon: info.icon)
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}
