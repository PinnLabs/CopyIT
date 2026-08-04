import AppKit
import Foundation

final class CopyItemUseCase {
    private let pasteboard: NSPasteboard
    private let imageFileStore: ImageFileStore

    init(
        pasteboard: NSPasteboard = .general,
        imageFileStore: ImageFileStore = ImageFileStore()
    ) {
        self.pasteboard = pasteboard
        self.imageFileStore = imageFileStore
    }

    func execute(item: ClipboardItem) {
        pasteboard.clearContents()
        if item.type == .image,
           let data = item.imageFileName.flatMap(imageFileStore.load),
           let rawType = item.imagePasteboardType {
            pasteboard.setData(data, forType: NSPasteboard.PasteboardType(rawType))
        } else {
            pasteboard.setString(item.content, forType: .string)
        }
    }
}
