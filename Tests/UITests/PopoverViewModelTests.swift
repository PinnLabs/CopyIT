@testable import ClipboardManager
import XCTest

@MainActor
final class PopoverViewModelTests: XCTestCase {
    private var store: MockClipboardStore!
    private var sut: PopoverViewModel!

    override func setUp() async throws {
        store = MockClipboardStore()
        sut = PopoverViewModel(
            fetchUseCase: FetchHistoryUseCase(store: store),
            copyUseCase: CopyItemUseCase(),
            deleteUseCase: DeleteItemUseCase(store: store),
            clearUseCase: ClearHistoryUseCase(store: store)
        )
    }

    override func tearDown() async throws {
        sut = nil
        store = nil
    }

    func test_refresh_loadsItemsFromStore() {
        store.savedItems = [ClipboardItem(content: "a", type: .text)]
        sut.refresh()
        XCTAssertEqual(sut.items.count, 1)
        XCTAssertEqual(sut.filteredItems.count, 1)
    }

    func test_searchText_filtersItemsCaseInsensitive() {
        store.savedItems = [
            ClipboardItem(content: "Hello World", type: .text),
            ClipboardItem(content: "Goodbye", type: .text)
        ]
        sut.refresh()
        sut.searchText = "hello"
        XCTAssertEqual(sut.filteredItems.count, 1)
        XCTAssertEqual(sut.filteredItems.first?.content, "Hello World")
    }

    func test_delete_removesAndRefreshes() {
        let target = ClipboardItem(content: "a", type: .text)
        store.savedItems = [target, ClipboardItem(content: "b", type: .text)]
        sut.refresh()
        sut.delete(target)
        XCTAssertEqual(sut.items.count, 1)
        XCTAssertEqual(sut.items.first?.content, "b")
    }

    func test_clearAll_emptiesItems() {
        store.savedItems = [ClipboardItem(content: "a", type: .text)]
        sut.refresh()
        sut.clearAll()
        XCTAssertTrue(sut.items.isEmpty)
    }

    func test_moveSelection_clampsAtBounds() {
        store.savedItems = [
            ClipboardItem(content: "a", type: .text),
            ClipboardItem(content: "b", type: .text)
        ]
        sut.refresh()
        sut.moveSelection(by: -1)
        XCTAssertEqual(sut.selectedIndex, 0)
        sut.moveSelection(by: 1)
        sut.moveSelection(by: 1)
        sut.moveSelection(by: 1)
        XCTAssertEqual(sut.selectedIndex, 1)
    }

    func test_deleteSelected_removesSelected() {
        let first = ClipboardItem(content: "a", type: .text)
        let second = ClipboardItem(content: "b", type: .text)
        store.savedItems = [first, second]
        sut.refresh()
        sut.moveSelection(by: 1)
        sut.deleteSelected()
        XCTAssertEqual(sut.items.count, 1)
        XCTAssertEqual(sut.items.first?.content, "a")
    }

    func test_isSelected_tracksSelectedItem() {
        let first = ClipboardItem(content: "a", type: .text)
        let second = ClipboardItem(content: "b", type: .text)
        store.savedItems = [first, second]
        sut.refresh()
        XCTAssertTrue(sut.isSelected(first))
        sut.moveSelection(by: 1)
        XCTAssertTrue(sut.isSelected(second))
    }

    func test_escape_withSearchText_clearsSearchInsteadOfClosing() {
        sut.searchText = "query"
        XCTAssertFalse(sut.handleEscape())
        XCTAssertEqual(sut.searchText, "")
    }

    func test_escape_withEmptySearch_closes() {
        XCTAssertTrue(sut.handleEscape())
    }
}
