import Foundation

final class FetchHistoryUseCase {
    private let store: ClipboardStoring

    init(store: ClipboardStoring) {
        self.store = store
    }

    func execute() -> [ClipboardItem] {
        store.fetchAll()
    }
}
