import AppKit
import Foundation

final class ClipboardMonitor: ClipboardMonitoring {
    var onNewItem: ((String) -> Void)?

    private let pollInterval: TimeInterval
    private let pasteboard: NSPasteboard
    private var timer: Timer?
    private var lastChangeCount: Int

    init(
        pollInterval: TimeInterval = 0.5,
        pasteboard: NSPasteboard = .general
    ) {
        self.pollInterval = pollInterval
        self.pasteboard = pasteboard
        self.lastChangeCount = pasteboard.changeCount
    }

    deinit { stopMonitoring() }

    func startMonitoring() {
        stopMonitoring()
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.checkForClipboardChanges()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func checkForClipboardChanges() {
        let current = pasteboard.changeCount
        guard current != lastChangeCount else { return }
        lastChangeCount = current
        guard let string = pasteboard.string(forType: .string) else { return }
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onNewItem?(string)
    }
}
