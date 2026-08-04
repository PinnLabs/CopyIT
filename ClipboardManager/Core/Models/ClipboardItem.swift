import Foundation

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let type: ClipboardItemType
    let createdAt: Date
    let imageData: Data?
    let imagePasteboardType: String?

    init(
        id: UUID = UUID(),
        content: String,
        type: ClipboardItemType,
        createdAt: Date = Date(),
        imageData: Data? = nil,
        imagePasteboardType: String? = nil
    ) {
        self.id = id
        self.content = content
        self.type = type
        self.createdAt = createdAt
        self.imageData = imageData
        self.imagePasteboardType = imagePasteboardType
    }

    static func from(
        imageData: Data,
        pasteboardType: String,
        now: Date = Date()
    ) -> ClipboardItem {
        ClipboardItem(
            content: "Image",
            type: .image,
            createdAt: now,
            imageData: imageData,
            imagePasteboardType: pasteboardType
        )
    }

    func hasSamePayload(as other: ClipboardItem) -> Bool {
        switch (type, other.type) {
        case (.image, .image):
            return imageData == other.imageData
        default:
            return content == other.content
        }
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
