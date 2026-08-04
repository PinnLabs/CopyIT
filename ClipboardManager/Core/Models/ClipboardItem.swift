import Foundation

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let type: ClipboardItemType
    let createdAt: Date
    let imagePasteboardType: String?
    let imageFileName: String?
    let imageDigest: String?
    let thumbnailFileName: String?
    // Resolved by the store for presentation and never JSON-encoded.
    let thumbnailFileURL: URL?
    // Decoded only from the short-lived legacy format for one-time migration.
    let legacyImageData: Data?

    init(
        id: UUID = UUID(),
        content: String,
        type: ClipboardItemType,
        createdAt: Date = Date(),
        imagePasteboardType: String? = nil,
        imageFileName: String? = nil,
        imageDigest: String? = nil,
        thumbnailFileName: String? = nil,
        thumbnailFileURL: URL? = nil,
        legacyImageData: Data? = nil
    ) {
        self.id = id
        self.content = content
        self.type = type
        self.createdAt = createdAt
        self.imagePasteboardType = imagePasteboardType
        self.imageFileName = imageFileName
        self.imageDigest = imageDigest
        self.thumbnailFileName = thumbnailFileName
        self.thumbnailFileURL = thumbnailFileURL
        self.legacyImageData = legacyImageData
    }

    func hasSamePayload(as other: ClipboardItem) -> Bool {
        switch (type, other.type) {
        case (.image, .image):
            if let imageDigest, let otherDigest = other.imageDigest {
                return imageDigest == otherDigest
            }
            return legacyImageData == other.legacyImageData
        default:
            return content == other.content
        }
    }

    func storedImage(
        imageFileName: String,
        imageDigest: String,
        thumbnailFileName: String?,
        thumbnailFileURL: URL?
    ) -> ClipboardItem {
        ClipboardItem(
            id: id,
            content: content,
            type: type,
            createdAt: createdAt,
            imagePasteboardType: imagePasteboardType,
            imageFileName: imageFileName,
            imageDigest: imageDigest,
            thumbnailFileName: thumbnailFileName,
            thumbnailFileURL: thumbnailFileURL
        )
    }

    func resolvingThumbnail(at url: URL?) -> ClipboardItem {
        ClipboardItem(
            id: id,
            content: content,
            type: type,
            createdAt: createdAt,
            imagePasteboardType: imagePasteboardType,
            imageFileName: imageFileName,
            imageDigest: imageDigest,
            thumbnailFileName: thumbnailFileName,
            thumbnailFileURL: url
        )
    }

    private enum CodingKeys: String, CodingKey {
        case id, content, type, createdAt
        case imageData // Legacy field: decoded for one-time migration only.
        case imagePasteboardType, imageFileName, imageDigest, thumbnailFileName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        type = try container.decode(ClipboardItemType.self, forKey: .type)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        legacyImageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
        imagePasteboardType = try container.decodeIfPresent(String.self, forKey: .imagePasteboardType)
        imageFileName = try container.decodeIfPresent(String.self, forKey: .imageFileName)
        imageDigest = try container.decodeIfPresent(String.self, forKey: .imageDigest)
        thumbnailFileName = try container.decodeIfPresent(String.self, forKey: .thumbnailFileName)
        thumbnailFileURL = nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(type, forKey: .type)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(imagePasteboardType, forKey: .imagePasteboardType)
        try container.encodeIfPresent(imageFileName, forKey: .imageFileName)
        try container.encodeIfPresent(imageDigest, forKey: .imageDigest)
        try container.encodeIfPresent(thumbnailFileName, forKey: .thumbnailFileName)
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
