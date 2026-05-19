import Foundation

final class DeleteItemUseCase {
    private let store: ClipboardStoring

    init(store: ClipboardStoring) {
        self.store = store
    }

    func execute(item: ClipboardItem) {
        store.delete(item)
    }
}
