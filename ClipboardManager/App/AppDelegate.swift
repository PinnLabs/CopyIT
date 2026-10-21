import AppKit
import Foundation

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBar: StatusBarController?
    private var monitor: ClipboardMonitoring?
    private var hotkey: HotkeyRegistering?
    private var store: ClipboardStoring?
    private var launchAtLogin: LaunchAtLoginManaging?
    private var settingsWindow: SettingsWindowController?
    private var pruneTimer: Timer?
    private var shutdownCoordinator: ShutdownCoordinator?

    private static let pruneInterval: TimeInterval = 60 * 60

    func applicationDidFinishLaunching(_ notification: Notification) {
        let imageFileStore = ImageFileStore()
        let preferences: PreferencesStoring = UserDefaultsPreferences()
        let store: ClipboardStoring = UserDefaultsStore(imageFileStore: imageFileStore, preferences: preferences)
        let ignoredApps: IgnoredAppsProviding = UserDefaultsIgnoredApps()
        let monitor: ClipboardMonitoring = ClipboardMonitor(ignoredApps: ignoredApps)
        let launchAtLogin: LaunchAtLoginManaging = LaunchAtLoginService()
        let shutdownCoordinator = ShutdownCoordinator(preferences: preferences, clearHistoryUseCase: ClearHistoryUseCase(store: store))
        shutdownCoordinator.handleLaunch()
        let pruneExpiredItems = PruneExpiredItemsUseCase(store: store, preferences: preferences)

        let viewModel = Self.makePopoverViewModel(store: store, imageFileStore: imageFileStore)

        let settingsWindow = Self.makeSettingsWindow(
            store: store, preferences: preferences, ignoredApps: ignoredApps,
            launchAtLogin: launchAtLogin, pruneExpiredItems: pruneExpiredItems
        )
        let statusBar = StatusBarController(
            viewModel: viewModel,
            monitor: monitor,
            onOpenSettings: { [weak settingsWindow] in settingsWindow?.show() },
            onWillShowPopover: { pruneExpiredItems.execute() }
        )
        startPruning(pruneExpiredItems, viewModel: viewModel)

        startCapture(monitor: monitor, store: store, imageFileStore: imageFileStore, viewModel: viewModel)

        startHotkey(statusBar: statusBar)

        // Launch at login is opt-in from Settings. Existing users stay registered: SMAppService keeps the
        // registration across launches, and nothing here calls disable().
        self.store = store
        self.monitor = monitor
        self.statusBar = statusBar
        self.launchAtLogin = launchAtLogin
        self.settingsWindow = settingsWindow
        self.shutdownCoordinator = shutdownCoordinator
    }

    // MARK: - Composition helpers

    private static func makeSettingsWindow(
        store: ClipboardStoring,
        preferences: PreferencesStoring,
        ignoredApps: IgnoredAppsProviding,
        launchAtLogin: LaunchAtLoginManaging,
        pruneExpiredItems: PruneExpiredItemsUseCase
    ) -> SettingsWindowController {
        SettingsWindowController(
            viewModel: SettingsViewModel(
                preferences: preferences,
                launchAtLogin: launchAtLogin,
                applyHistoryLimitUseCase: ApplyHistoryLimitUseCase(store: store, preferences: preferences)
            ),
            privacyViewModel: PrivacySettingsViewModel(
                preferences: preferences,
                ignoredApps: ignoredApps,
                appInfo: WorkspaceAppInfo(),
                pruneExpiredItemsUseCase: pruneExpiredItems
            )
        )
    }

    private static func makePopoverViewModel(store: ClipboardStoring, imageFileStore: ImageFileStore) -> PopoverViewModel {
        PopoverViewModel(
            fetchUseCase: FetchHistoryUseCase(store: store),
            copyUseCase: CopyItemUseCase(imageFileStore: imageFileStore),
            deleteUseCase: DeleteItemUseCase(store: store),
            clearUseCase: ClearHistoryUseCase(store: store)
        )
    }

    /// Prunes now, then every hour.
    private func startPruning(_ pruneExpiredItems: PruneExpiredItemsUseCase, viewModel: PopoverViewModel) {
        pruneExpiredItems.execute()
        pruneTimer = Timer.scheduledTimer(withTimeInterval: Self.pruneInterval, repeats: true) { [weak viewModel] _ in
            pruneExpiredItems.execute()
            Task { @MainActor in viewModel?.refresh() }
        }
    }

    private func startHotkey(statusBar: StatusBarController) {
        let hotkey: HotkeyRegistering = HotkeyManager()
        self.hotkey = hotkey
        hotkey.onHotkeyTriggered = { [weak statusBar] in
            Task { @MainActor in statusBar?.togglePopover() }
        }
        hotkey.register()
    }

    private func startCapture(
        monitor: ClipboardMonitoring,
        store: ClipboardStoring,
        imageFileStore: ImageFileStore,
        viewModel: PopoverViewModel
    ) {
        let ingestion: ClipboardIngesting = ImageIngestionService(imageFileStore: imageFileStore)
        monitor.onNewItem = { [weak viewModel] capture in
            ingestion.ingest(capture) { item in
                store.save(item)
                viewModel?.refresh()
            }
        }
        monitor.startMonitoring()
    }

    func openSettings() {
        settingsWindow?.show()
    }

    func applicationWillTerminate(_ notification: Notification) {
        pruneTimer?.invalidate()
        pruneTimer = nil
        monitor?.stopMonitoring()
        hotkey?.unregister()
        shutdownCoordinator?.handleTerminate()
    }
}
