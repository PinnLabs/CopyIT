import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    let historyLimitOptions = HistoryLimit.options
    let shortcutDescription = "⌥Space"
    let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "–"
    let repositoryURL = URL(string: "https://github.com/PinnLabs/CopyIT")

    private(set) var isLaunchAtLoginEnabled = false
    private(set) var launchAtLoginRequiresApproval = false
    var historyLimit: Int {
        didSet {
            guard historyLimit != oldValue else { return }
            preferences.historyLimit = historyLimit
            applyHistoryLimitUseCase.execute()
        }
    }

    private let preferences: PreferencesStoring
    private let launchAtLogin: LaunchAtLoginManaging
    private let applyHistoryLimitUseCase: ApplyHistoryLimitUseCase

    init(
        preferences: PreferencesStoring,
        launchAtLogin: LaunchAtLoginManaging,
        applyHistoryLimitUseCase: ApplyHistoryLimitUseCase
    ) {
        self.preferences = preferences
        self.launchAtLogin = launchAtLogin
        self.applyHistoryLimitUseCase = applyHistoryLimitUseCase
        historyLimit = preferences.historyLimit
        refresh()
    }

    // MARK: - Launch at login

    /// Re-reads the real SMAppService state; the toggle never trusts a separately saved value.
    func refresh() {
        launchAtLoginRequiresApproval = launchAtLogin.requiresApproval
        isLaunchAtLoginEnabled = launchAtLogin.isEnabled || launchAtLoginRequiresApproval
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try launchAtLogin.enable()
            } else {
                try launchAtLogin.disable()
            }
        } catch {
            AppLogger.launchAtLogin.error("Failed to update login item: \(error.localizedDescription, privacy: .public)")
        }
        refresh()
    }

    func openLoginItemsSettings() {
        launchAtLogin.openSystemSettings()
    }
}
