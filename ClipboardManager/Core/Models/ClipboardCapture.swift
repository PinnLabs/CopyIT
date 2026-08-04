import Foundation

enum ClipboardCapture: Equatable {
    case text(String)
    case image(data: Data, pasteboardType: String)
}
