import AppKit
import Foundation

final class CopyItemUseCase {
    private let pasteboard: NSPasteboard

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    func execute(item: ClipboardItem) {
        pasteboard.clearContents()
        if item.type == .image,
           let data = item.imageData,
           let rawType = item.imagePasteboardType {
            pasteboard.setData(data, forType: NSPasteboard.PasteboardType(rawType))
        } else {
            pasteboard.setString(item.content, forType: .string)
        }
    }
}
