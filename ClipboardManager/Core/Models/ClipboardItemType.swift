import Foundation

enum ClipboardItemType: String, Codable, Equatable {
    case text
    case url
    case image
    case unknown
}
