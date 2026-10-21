import Foundation
import ImageIO

/// Hashes, writes and thumbnails captured images on a serial background queue. Text goes through the
/// same queue so items are delivered in the order they were copied.
final class ImageIngestionService: ClipboardIngesting, Sendable {
    private let queue = DispatchQueue(label: "com.copyit.image-ingestion", qos: .userInitiated)
    private let imageFileStore: ImageFileStore

    init(imageFileStore: ImageFileStore) {
        self.imageFileStore = imageFileStore
    }

    func ingest(_ capture: ClipboardCapture, completion: @escaping @MainActor (ClipboardItem) -> Void) {
        // Safe: the closure is only ever called on the main actor, below; the queue just carries it.
        nonisolated(unsafe) let completion = completion
        queue.async { [imageFileStore] in
            guard let item = Self.makeItem(from: capture, imageFileStore: imageFileStore) else { return }
            DispatchQueue.main.async {
                MainActor.assumeIsolated { completion(item) }
            }
        }
    }

    private static func makeItem(from capture: ClipboardCapture, imageFileStore: ImageFileStore) -> ClipboardItem? {
        switch capture {
        case let .text(raw):
            return ClipboardItem.from(pasteboardString: raw)
        case let .image(data, pasteboardType):
            guard isDecodableImage(data),
                  let stored = imageFileStore.store(data: data, pasteboardType: pasteboardType) else {
                AppLogger.store.warning("Skipped clipboard image that couldn't be decoded or stored")
                return nil
            }
            return ClipboardItem(
                content: "Image",
                type: .image,
                imagePasteboardType: pasteboardType
            ).storedImage(
                imageFileName: stored.imageFileName,
                imageDigest: stored.digest,
                thumbnailFileName: stored.thumbnailFileName,
                thumbnailFileURL: imageFileStore.thumbnailURL(fileName: stored.thumbnailFileName)
            )
        }
    }

    private static func isDecodableImage(_ data: Data) -> Bool {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return false }
        return CGImageSourceGetCount(source) > 0
    }
}
