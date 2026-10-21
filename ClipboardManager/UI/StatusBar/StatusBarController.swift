import AppKit
import SwiftUI

@MainActor
final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private let viewModel: PopoverViewModel
    private let monitor: ClipboardMonitoring
    private let onOpenSettings: () -> Void
    private var eventMonitor: Any?
    private var resumeTimer: Timer?

    private static let fifteenMinutes: TimeInterval = 15 * 60
    private static let oneHour: TimeInterval = 60 * 60

    init(
        viewModel: PopoverViewModel,
        monitor: ClipboardMonitoring,
        onOpenSettings: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.monitor = monitor
        self.onOpenSettings = onOpenSettings
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.popover = NSPopover()
        super.init()
        configurePopover()
        configureStatusItem()
    }

    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    func togglePopover() {
        popover.isShown ? closePopover() : showPopover()
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 360, height: 480)
        popover.contentViewController = NSHostingController(
            rootView: PopoverView(
                viewModel: viewModel,
                onQuit: { NSApp.terminate(nil) },
                onOpenSettings: { [weak self] in self?.menuSettings() },
                onClose: { [weak self] in self?.closePopover() }
            )
        )
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }
        let image = NSImage(named: "MenuBarIcon")
            ?? NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: nil)
        image?.size = NSSize(width: 18, height: 18)
        image?.isTemplate = true
        image?.accessibilityDescription = "CopyIT"
        button.image = image
        button.action = #selector(handleClick(_:))
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover()
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: "Open Clipboard", action: #selector(menuOpen), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Settings…", action: #selector(menuSettings), keyEquivalent: ",").target = self
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Clear History", action: #selector(menuClear), keyEquivalent: "").target = self
        menu.addItem(makePauseMenuItem())
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit ClipboardManager", action: #selector(menuQuit), keyEquivalent: "q").target = self
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func menuOpen() { showPopover() }
    @objc private func menuSettings() {
        closePopover()
        onOpenSettings()
    }
    @objc private func menuClear() { viewModel.clearAll() }
    @objc private func menuQuit() { NSApp.terminate(nil) }

    // MARK: - Pause

    private func makePauseMenuItem() -> NSMenuItem {
        if monitor.isPaused {
            let item = NSMenuItem(title: "Resume Capture", action: #selector(menuResume), keyEquivalent: "")
            item.target = self
            return item
        }
        let submenu = NSMenu()
        submenu.addItem(withTitle: "For 15 Minutes", action: #selector(menuPause15Minutes), keyEquivalent: "").target = self
        submenu.addItem(withTitle: "For 1 Hour", action: #selector(menuPause1Hour), keyEquivalent: "").target = self
        submenu.addItem(withTitle: "Until Resumed", action: #selector(menuPauseIndefinitely), keyEquivalent: "").target = self
        let item = NSMenuItem(title: "Pause Capture", action: nil, keyEquivalent: "")
        item.submenu = submenu
        return item
    }

    @objc private func menuPause15Minutes() { pause(for: Self.fifteenMinutes) }
    @objc private func menuPause1Hour() { pause(for: Self.oneHour) }
    @objc private func menuPauseIndefinitely() { pause(for: nil) }

    @objc private func menuResume() {
        monitor.resume()
        updatePauseAppearance()
    }

    private func pause(for interval: TimeInterval?) {
        let deadline = interval.map { Date().addingTimeInterval($0) }
        monitor.pause(until: deadline)
        updatePauseAppearance()
        guard let deadline else { return }
        // Un-dim the icon when the timed pause expires on its own.
        resumeTimer = Timer.scheduledTimer(withTimeInterval: deadline.timeIntervalSinceNow, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.updatePauseAppearance() }
        }
    }

    private func updatePauseAppearance() {
        resumeTimer?.invalidate()
        resumeTimer = nil
        statusItem.button?.appearsDisabled = monitor.isPaused
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        viewModel.refresh()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
        startEventMonitor()
    }

    private func closePopover() {
        popover.performClose(nil)
        stopEventMonitor()
    }

    private func startEventMonitor() {
        guard eventMonitor == nil else { return }
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in self?.closePopover() }
        }
    }

    private func stopEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}
