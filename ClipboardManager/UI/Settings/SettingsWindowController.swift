import AppKit
import SwiftUI

/// Hosts SettingsView in an AppKit window: the SwiftUI Settings scene misbehaves in LSUIElement apps
/// (opens behind other windows, can't be opened reliably from an NSMenu).
@MainActor
final class SettingsWindowController: NSWindowController {
    private let viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        let window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView(viewModel: viewModel)))
        window.title = "CopyIT Settings"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func show() {
        guard let window else { return }
        if !window.isVisible {
            viewModel.refresh()
            window.center()
        }
        NSApp.activate()
        showWindow(nil)
        window.makeKeyAndOrderFront(nil)
    }
}
