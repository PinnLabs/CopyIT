import AppKit
import Foundation

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBar: StatusBarController?
    private var monitor: ClipboardMonitoring?
    private var hotkey: HotkeyRegistering?
    private var store: ClipboardStoring?
    private var launchAtLogin: LaunchAtLoginManaging?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let imageFileStore = ImageFileStore()
        let store: ClipboardStoring = UserDefaultsStore(imageFileStore: imageFileStore)
        let monitor: ClipboardMonitoring = ClipboardMonitor()
        let hotkey: HotkeyRegistering = HotkeyManager()
        let launchAtLogin: LaunchAtLoginManaging = LaunchAtLoginService()

        let viewModel = PopoverViewModel(
            fetchUseCase: FetchHistoryUseCase(store: store),
            copyUseCase: CopyItemUseCase(imageFileStore: imageFileStore),
            deleteUseCase: DeleteItemUseCase(store: store),
            clearUseCase: ClearHistoryUseCase(store: store)
        )

        let statusBar = StatusBarController(viewModel: viewModel, monitor: monitor)

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

        do {
            try launchAtLogin.enable()
        } catch {
            AppLogger.launchAtLogin.error("Failed to register: \(error.localizedDescription, privacy: .public)")
        }

        self.store = store
        self.monitor = monitor
        self.hotkey = hotkey
        self.statusBar = statusBar
        self.launchAtLogin = launchAtLogin
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor?.stopMonitoring()
        hotkey?.unregister()
    }
}
