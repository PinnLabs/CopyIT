import XCTest
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
}
