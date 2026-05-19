import Foundation

final class ClearHistoryUseCase {
    private let store: ClipboardStoring

    init(store: ClipboardStoring) {
        self.store = store
    }

    func execute() {
        store.clear()
    }
}
