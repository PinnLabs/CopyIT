import CryptoKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

final class ImageFileStore {
    struct StoredImage {
        let digest: String
        let imageFileName: String
        let thumbnailFileName: String?
    }

    static let maxItemBytes = 10 * 1_024 * 1_024
    static let maxTotalBytes = 100 * 1_024 * 1_024

    private let fileManager: FileManager
    private let directoryURL: URL

    init(
        fileManager: FileManager = .default,
        directoryURL: URL? = nil
    ) {
        self.fileManager = fileManager
        self.directoryURL = directoryURL ?? Self.defaultDirectoryURL(fileManager: fileManager)
    }

    func store(data: Data, pasteboardType: String) -> StoredImage? {
        guard !data.isEmpty, data.count <= Self.maxItemBytes else { return nil }
        guard ensureDirectoryExists() else { return nil }

        let digest = digest(for: data)
        let fileExtension = UTType(pasteboardType)?.preferredFilenameExtension ?? "data"
        let imageFileName = "\(digest).\(fileExtension)"
        let imageURL = directoryURL.appendingPathComponent(imageFileName)

        do {
            if !fileManager.fileExists(atPath: imageURL.path) {
                try data.write(to: imageURL, options: .atomic)
            }

            let thumbnailFileName = storeThumbnail(from: data, digest: digest)
            return StoredImage(
                digest: digest,
                imageFileName: imageFileName,
                thumbnailFileName: thumbnailFileName
            )
        } catch {
            AppLogger.store.error("Failed to store clipboard image: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    func load(fileName: String) -> Data? {
        try? Data(contentsOf: fileURL(for: fileName), options: .mappedIfSafe)
    }

    func fileSize(fileName: String) -> Int {
        let attributes = try? fileManager.attributesOfItem(atPath: fileURL(for: fileName).path)
        return (attributes?[.size] as? NSNumber)?.intValue ?? 0
    }

    func thumbnailURL(fileName: String?) -> URL? {
        guard let fileName else { return nil }
        let url = fileURL(for: fileName)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    func delete(imageFileName: String?, thumbnailFileName: String?) {
        for fileName in [imageFileName, thumbnailFileName].compactMap({ $0 }) {
            try? fileManager.removeItem(at: fileURL(for: fileName))
        }
    }

    func clear() {
        try? fileManager.removeItem(at: directoryURL)
    }

    private func digest(for data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private func storeThumbnail(from data: Data, digest: String) -> String? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 96
        ]
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        let fileName = "\(digest)-thumbnail.png"
        let url = fileURL(for: fileName)
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else { return nil }

        CGImageDestinationAddImage(destination, thumbnail, nil)
        return CGImageDestinationFinalize(destination) ? fileName : nil
    }

    private func ensureDirectoryExists() -> Bool {
        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            return true
        } catch {
            AppLogger.store.error("Failed to create image directory: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    private func fileURL(for fileName: String) -> URL {
        directoryURL.appendingPathComponent(fileName)
    }

    private static func defaultDirectoryURL(fileManager: FileManager) -> URL {
        let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return applicationSupport
            .appendingPathComponent("CopyIT", isDirectory: true)
            .appendingPathComponent("ClipboardImages", isDirectory: true)
    }
}
