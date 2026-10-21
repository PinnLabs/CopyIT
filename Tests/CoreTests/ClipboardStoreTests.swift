import AppKit
@testable import ClipboardManager
import XCTest

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

    func test_saveAndFetch_persistsImageOutsideUserDefaults() throws {
        let data = Data([1, 2, 3, 4])
        let item = makeStoredImage(data: data)

        sut.save(item)

        let savedItem = sut.fetchAll().first
        XCTAssertNil(savedItem?.legacyImageData)
        XCTAssertEqual(savedItem?.type, .image)
        XCTAssertNotNil(savedItem?.imageFileName)
        XCTAssertEqual(savedItem?.imageFileName.flatMap(imageFileStore.load), data)
        XCTAssertFalse(try XCTUnwrap(try String(data: XCTUnwrap(defaults.data(forKey: "com.copyit.clipboard.history")), encoding: .utf8)?
                .contains("AQIDBA==")))
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
        try defaults.set(
            JSONSerialization.data(withJSONObject: legacyJSON),
            forKey: "com.copyit.clipboard.history"
        )

        let migratedItem = try XCTUnwrap(sut.fetchAll().first)

        XCTAssertNil(migratedItem.legacyImageData)
        XCTAssertEqual(migratedItem.imageFileName.flatMap(imageFileStore.load), legacyData)
        let persistedJSON = try XCTUnwrap(
            try String(data: XCTUnwrap(defaults.data(forKey: "com.copyit.clipboard.history")), encoding: .utf8)
        )
        XCTAssertFalse(persistedJSON.contains("BQYH"))
    }

    func test_save_capsAtPreferencesHistoryLimit() {
        sut = UserDefaultsStore(
            defaults: defaults,
            imageFileStore: imageFileStore,
            preferences: MockPreferences(historyLimit: 25)
        )
        for index in 0 ..< 30 {
            sut.save(ClipboardItem(content: "item-\(index)", type: .text))
        }
        XCTAssertEqual(sut.fetchAll().count, 25)
        XCTAssertEqual(sut.fetchAll().first?.content, "item-29")
    }

    // MARK: - ApplyHistoryLimitUseCase

    func test_applyHistoryLimit_trimsToNewLimitAndDeletesRemovedImages() throws {
        let preferences = MockPreferences(historyLimit: 50)
        sut = UserDefaultsStore(defaults: defaults, imageFileStore: imageFileStore, preferences: preferences)
        let oldImage = makeStoredImage(data: Data([0x89, 0x50, 0x4E, 0x47, 0x01]))
        sut.save(oldImage)
        for index in 0 ..< 25 {
            sut.save(ClipboardItem(content: "item-\(index)", type: .text))
        }
        let imageFileName = try XCTUnwrap(oldImage.imageFileName)
        XCTAssertNotNil(imageFileStore.load(fileName: imageFileName))

        preferences.historyLimit = 25
        ApplyHistoryLimitUseCase(store: sut, preferences: preferences).execute()

        let items = sut.fetchAll()
        XCTAssertEqual(items.count, 25)
        XCTAssertFalse(items.contains { $0.id == oldImage.id })
        XCTAssertNil(imageFileStore.load(fileName: imageFileName))
    }

    // MARK: - PruneExpiredItemsUseCase

    private let pruneNow = Date(timeIntervalSince1970: 1_000_000_000)
    private let oneDay: TimeInterval = 24 * 60 * 60

    func test_pruneExpiredItems_deletesOnlyItemsOlderThanRetention() {
        let preferences = MockPreferences()
        preferences.retention = .sevenDays
        sut.save(ClipboardItem(content: "old", type: .text, createdAt: pruneNow.addingTimeInterval(-8 * oneDay)))
        sut.save(ClipboardItem(content: "recent", type: .text, createdAt: pruneNow.addingTimeInterval(-6 * oneDay)))

        PruneExpiredItemsUseCase(store: sut, preferences: preferences, now: { self.pruneNow }).execute()

        XCTAssertEqual(sut.fetchAll().map(\.content), ["recent"])
    }

    func test_pruneExpiredItems_withForever_keepsEverything() {
        let preferences = MockPreferences()
        sut.save(ClipboardItem(content: "ancient", type: .text, createdAt: Date(timeIntervalSince1970: 0)))

        PruneExpiredItemsUseCase(store: sut, preferences: preferences, now: { self.pruneNow }).execute()

        XCTAssertEqual(sut.fetchAll().count, 1)
    }

    func test_pruneExpiredItems_deletesImagesOfRemovedItems() throws {
        let preferences = MockPreferences()
        preferences.retention = .oneDay
        let image = makeStoredImage(data: Data([0x89, 0x50, 0x4E, 0x47, 0x02]), createdAt: pruneNow.addingTimeInterval(-2 * oneDay))
        sut.save(image)
        let imageFileName = try XCTUnwrap(image.imageFileName)

        PruneExpiredItemsUseCase(store: sut, preferences: preferences, now: { self.pruneNow }).execute()

        XCTAssertTrue(sut.fetchAll().isEmpty)
        XCTAssertNil(imageFileStore.load(fileName: imageFileName))
    }

    private func makeStoredImage(data: Data, createdAt: Date = Date()) -> ClipboardItem {
        let stored = imageFileStore.store(data: data, pasteboardType: "public.png")!
        return ClipboardItem(
            content: "Image",
            type: .image,
            createdAt: createdAt,
            imagePasteboardType: "public.png"
        ).storedImage(
            imageFileName: stored.imageFileName,
            imageDigest: stored.digest,
            thumbnailFileName: stored.thumbnailFileName,
            thumbnailFileURL: imageFileStore.thumbnailURL(fileName: stored.thumbnailFileName)
        )
    }
}
