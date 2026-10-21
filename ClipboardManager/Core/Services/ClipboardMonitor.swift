import AppKit
import Foundation
import UniformTypeIdentifiers

final class ClipboardMonitor: ClipboardMonitoring {
    var onNewItem: ((ClipboardCapture) -> Void)?

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

    func checkForClipboardChanges() {
        let current = pasteboard.changeCount
        guard current != lastChangeCount else { return }
        lastChangeCount = current

        if let imageCapture = makeImageCapture() {
            onNewItem?(imageCapture)
            return
        }

        guard let string = pasteboard.string(forType: .string) else { return }
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onNewItem?(.text(string))
    }

    private func makeImageCapture() -> ClipboardCapture? {
        let preferredTypes: [NSPasteboard.PasteboardType] = [.png, .tiff]
        let otherImageTypes = (pasteboard.types ?? []).filter { type in
            !preferredTypes.contains(type) && UTType(type.rawValue)?.conforms(to: .image) == true
        }

        for type in preferredTypes + otherImageTypes {
            if let data = pasteboard.data(forType: type), !data.isEmpty {
                guard data.count <= ImageFileStore.maxItemBytes else {
                    AppLogger.monitor.warning("Skipped image larger than the 10 MB item limit")
                    return nil
                }
                return .image(data: data, pasteboardType: type.rawValue)
            }
        }
        return nil
    }
}
