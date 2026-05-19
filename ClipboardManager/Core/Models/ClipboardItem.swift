import Foundation

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let type: ClipboardItemType
    let createdAt: Date

    init(
        id: UUID = UUID(),
        content: String,
        type: ClipboardItemType,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.content = content
        self.type = type
        self.createdAt = createdAt
    }

    static func from(pasteboardString: String, now: Date = Date()) -> ClipboardItem {
        ClipboardItem(
            id: UUID(),
            content: pasteboardString,
            type: detectType(for: pasteboardString),
            createdAt: now
        )
    }

    private static func detectType(for raw: String) -> ClipboardItemType {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .unknown }
        if let url = URL(string: trimmed), let scheme = url.scheme, !scheme.isEmpty {
            return .url
        }
        return .text
    }
}
