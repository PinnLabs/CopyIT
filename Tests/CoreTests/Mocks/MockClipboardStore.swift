import Foundation
@testable import ClipboardManager

final class MockClipboardStore: ClipboardStoring {
    var savedItems: [ClipboardItem] = []
    private(set) var clearCalled = false

    func save(_ item: ClipboardItem) {
        savedItems.removeAll { $0.content == item.content }
        savedItems.insert(item, at: 0)
    }

    func fetchAll() -> [ClipboardItem] {
        savedItems
    }

    func delete(_ item: ClipboardItem) {
        savedItems.removeAll { $0.id == item.id }
    }

    func clear() {
        savedItems.removeAll()
        clearCalled = true
    }
}
