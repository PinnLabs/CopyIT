import XCTest
import AppKit
@testable import ClipboardManager

final class ClipboardStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var sut: UserDefaultsStore!
    private var imageFileStore: ImageFileStore!
    private var imageDirectory: URL!
    private let suiteName = "ClipboardStoreTests.suite"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        imageDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ClipboardStoreTests-\(UUID().uuidString)")
        imageFileStore = ImageFileStore(directoryURL: imageDirectory)
        sut = UserDefaultsStore(defaults: defaults, imageFileStore: imageFileStore)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        try? FileManager.default.removeItem(at: imageDirectory)
        sut = nil
        imageFileStore = nil
        imageDirectory = nil
        defaults = nil
        super.tearDown()
    }

    func test_saveAndFetch_returnsSavedItems() {
        let item = ClipboardItem(content: "hello", type: .text)
        sut.save(item)
        XCTAssertEqual(sut.fetchAll().first?.content, "hello")
    }

    func test_delete_removesItem() {
        let item = ClipboardItem(content: "hello", type: .text)
        sut.save(item)
        sut.delete(item)
        XCTAssertTrue(sut.fetchAll().isEmpty)
    }

    func test_clear_emptiesStore() {
        sut.save(ClipboardItem(content: "a", type: .text))
        sut.save(ClipboardItem(content: "b", type: .text))
        sut.clear()
        XCTAssertTrue(sut.fetchAll().isEmpty)
    }

    func test_save_dedupesByContent() {
        sut.save(ClipboardItem(content: "x", type: .text))
        sut.save(ClipboardItem(content: "x", type: .text))
        XCTAssertEqual(sut.fetchAll().count, 1)
    }

    func test_saveAndFetch_persistsImageOutsideUserDefaults() {
        let data = Data([1, 2, 3, 4])
        let item = makeStoredImage(data: data)

        sut.save(item)

        let savedItem = sut.fetchAll().first
        XCTAssertNil(savedItem?.legacyImageData)
        XCTAssertEqual(savedItem?.type, .image)
        XCTAssertNotNil(savedItem?.imageFileName)
        XCTAssertEqual(savedItem?.imageFileName.flatMap(imageFileStore.load), data)
        XCTAssertFalse(String(data: defaults.data(forKey: "com.copyit.clipboard.history")!, encoding: .utf8)!.contains("AQIDBA=="))
    }

    func test_save_dedupesImagesByDataInsteadOfDisplayLabel() {
        sut.save(makeStoredImage(data: Data([1])))
        sut.save(makeStoredImage(data: Data([2])))
        sut.save(makeStoredImage(data: Data([1])))

        let items = sut.fetchAll()
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items.first?.imageFileName.flatMap(imageFileStore.load), Data([1]))
    }

    func test_save_skipsImageAbovePerItemBudget() {
        let oversizedData = Data(count: ImageFileStore.maxItemBytes + 1)

        let stored = imageFileStore.store(data: oversizedData, pasteboardType: "public.png")

        XCTAssertNil(stored)
    }

    func test_store_generatesSmallThumbnailDuringIngestion() throws {
        let representation = try XCTUnwrap(NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: 400,
            pixelsHigh: 200,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ))
        let imageData = try XCTUnwrap(representation.representation(using: .png, properties: [:]))

        let stored = try XCTUnwrap(imageFileStore.store(data: imageData, pasteboardType: "public.png"))
        let thumbnailURL = try XCTUnwrap(imageFileStore.thumbnailURL(fileName: stored.thumbnailFileName))
        let thumbnail = try XCTUnwrap(NSImage(contentsOf: thumbnailURL))

        XCTAssertLessThanOrEqual(max(thumbnail.size.width, thumbnail.size.height), 96)
    }

    func test_fetchAll_migratesLegacyImageDataToFileStorage() throws {
        let legacyData = Data([5, 6, 7])
        let legacyJSON: [[String: Any]] = [[
            "id": UUID().uuidString,
            "content": "Image",
            "type": "image",
            "createdAt": Date().timeIntervalSinceReferenceDate,
            "imageData": legacyData.base64EncodedString(),
            "imagePasteboardType": "public.png"
        ]]
        defaults.set(
            try JSONSerialization.data(withJSONObject: legacyJSON),
            forKey: "com.copyit.clipboard.history"
        )

        let migratedItem = try XCTUnwrap(sut.fetchAll().first)

        XCTAssertNil(migratedItem.legacyImageData)
        XCTAssertEqual(migratedItem.imageFileName.flatMap(imageFileStore.load), legacyData)
        let persistedJSON = try XCTUnwrap(
            String(data: defaults.data(forKey: "com.copyit.clipboard.history")!, encoding: .utf8)
        )
        XCTAssertFalse(persistedJSON.contains("BQYH"))
    }

    func test_save_capsAt50Items() {
        for index in 0..<60 {
            sut.save(ClipboardItem(content: "item-\(index)", type: .text))
        }
        XCTAssertEqual(sut.fetchAll().count, UserDefaultsStore.maxHistoryCount)
    }

    private func makeStoredImage(data: Data) -> ClipboardItem {
        let stored = imageFileStore.store(data: data, pasteboardType: "public.png")!
        return ClipboardItem(
            content: "Image",
            type: .image,
            imagePasteboardType: "public.png"
        ).storedImage(
            imageFileName: stored.imageFileName,
            imageDigest: stored.digest,
            thumbnailFileName: stored.thumbnailFileName,
            thumbnailFileURL: imageFileStore.thumbnailURL(fileName: stored.thumbnailFileName)
        )
    }
}
