import AppKit
import Foundation
import UniformTypeIdentifiers

final class ClipboardMonitor: ClipboardMonitoring {
    var onNewItem: ((ClipboardItem) -> Void)?

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

        if let imageItem = makeImageItem() {
            onNewItem?(imageItem)
            return
        }

        guard let string = pasteboard.string(forType: .string) else { return }
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onNewItem?(ClipboardItem.from(pasteboardString: string))
    }

    private func makeImageItem() -> ClipboardItem? {
        let preferredTypes: [NSPasteboard.PasteboardType] = [.png, .tiff]
        let otherImageTypes = (pasteboard.types ?? []).filter { type in
            !preferredTypes.contains(type) && UTType(type.rawValue)?.conforms(to: .image) == true
        }

        for type in preferredTypes + otherImageTypes {
            if let data = pasteboard.data(forType: type), !data.isEmpty {
                return ClipboardItem.from(imageData: data, pasteboardType: type.rawValue)
            }
        }
        return nil
    }
}
