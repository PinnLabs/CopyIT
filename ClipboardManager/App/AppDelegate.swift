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

    func applicationDidFinishLaunching(_ notification: Notification) {
        let imageFileStore = ImageFileStore()
        let preferences: PreferencesStoring = UserDefaultsPreferences()
        let store: ClipboardStoring = UserDefaultsStore(imageFileStore: imageFileStore, preferences: preferences)
        let monitor: ClipboardMonitoring = ClipboardMonitor()
        let hotkey: HotkeyRegistering = HotkeyManager()
        let launchAtLogin: LaunchAtLoginManaging = LaunchAtLoginService()

        let viewModel = PopoverViewModel(
            fetchUseCase: FetchHistoryUseCase(store: store),
            copyUseCase: CopyItemUseCase(imageFileStore: imageFileStore),
            deleteUseCase: DeleteItemUseCase(store: store),
            clearUseCase: ClearHistoryUseCase(store: store)
        )

        let settingsWindow = SettingsWindowController(
            viewModel: SettingsViewModel(
                preferences: preferences,
                launchAtLogin: launchAtLogin,
                applyHistoryLimitUseCase: ApplyHistoryLimitUseCase(store: store, preferences: preferences)
            )
        )
        let statusBar = StatusBarController(viewModel: viewModel, monitor: monitor) { [weak settingsWindow] in
            settingsWindow?.show()
        }

        monitor.onNewItem = { [weak viewModel] capture in
            let item: ClipboardItem
            switch capture {
            case .text(let raw):
                item = ClipboardItem.from(pasteboardString: raw)
            case .image(let data, let pasteboardType):
                guard let stored = imageFileStore.store(data: data, pasteboardType: pasteboardType) else {
                    return
                }
                item = ClipboardItem(
                    content: "Image",
                    type: .image,
                    imagePasteboardType: pasteboardType
                ).storedImage(
                    imageFileName: stored.imageFileName,
                    imageDigest: stored.digest,
                    thumbnailFileName: stored.thumbnailFileName,
                    thumbnailFileURL: imageFileStore.thumbnailURL(fileName: stored.thumbnailFileName)
                )
            }
            store.save(item)
            Task { @MainActor in viewModel?.refresh() }
        }
        monitor.startMonitoring()

        hotkey.onHotkeyTriggered = { [weak statusBar] in
            Task { @MainActor in statusBar?.togglePopover() }
        }
        hotkey.register()

        // Launch at login is opt-in from Settings. Existing users stay registered: SMAppService keeps the
        // registration across launches, and nothing here calls disable().
        self.store = store
        self.monitor = monitor
        self.hotkey = hotkey
        self.statusBar = statusBar
        self.launchAtLogin = launchAtLogin
        self.settingsWindow = settingsWindow
    }

    func openSettings() {
        settingsWindow?.show()
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor?.stopMonitoring()
        hotkey?.unregister()
    }
}
