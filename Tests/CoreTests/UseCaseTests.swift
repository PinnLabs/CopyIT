import XCTest
import AppKit
@testable import ClipboardManager

final class UseCaseTests: XCTestCase {
    private var store: MockClipboardStore!

    override func setUp() {
        super.setUp()
        store = MockClipboardStore()
    }

    override func tearDown() {
        store = nil
        super.tearDown()
    }

    func test_fetchHistory_returnsAllItems() {
        store.savedItems = [ClipboardItem(content: "a", type: .text)]
        let sut = FetchHistoryUseCase(store: store)
        XCTAssertEqual(sut.execute().count, 1)
    }

    func test_deleteItem_removesFromStore() {
        let item = ClipboardItem(content: "a", type: .text)
        store.savedItems = [item]
        let sut = DeleteItemUseCase(store: store)
        sut.execute(item: item)
        XCTAssertTrue(store.savedItems.isEmpty)
    }

    func test_clearHistory_clearsStore() {
        store.savedItems = [
            ClipboardItem(content: "a", type: .text),
            ClipboardItem(content: "b", type: .text)
        ]
        let sut = ClearHistoryUseCase(store: store)
        sut.execute()
        XCTAssertTrue(store.clearCalled)
        XCTAssertTrue(store.savedItems.isEmpty)
    }

    func test_copyItem_writesPersistedImageBackToPasteboard() throws {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(UUID().uuidString))
        let data = Data([1, 2, 3])
        let imageDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CopyItemUseCaseTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: imageDirectory) }
        let imageFileStore = ImageFileStore(directoryURL: imageDirectory)
        let stored = try XCTUnwrap(imageFileStore.store(data: data, pasteboardType: "public.png"))
        let item = ClipboardItem(
            content: "Image",
            type: .image,
            imagePasteboardType: NSPasteboard.PasteboardType.png.rawValue
        ).storedImage(
            imageFileName: stored.imageFileName,
            imageDigest: stored.digest,
            thumbnailFileName: stored.thumbnailFileName,
            thumbnailFileURL: nil
        )
        let sut = CopyItemUseCase(pasteboard: pasteboard, imageFileStore: imageFileStore)

        sut.execute(item: item)

        XCTAssertEqual(pasteboard.data(forType: .png), data)
    }
}
