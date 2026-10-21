import Foundation

final class ApplyHistoryLimitUseCase {
    private let store: ClipboardStoring
    private let preferences: PreferencesStoring

    init(store: ClipboardStoring, preferences: PreferencesStoring) {
        self.store = store
        self.preferences = preferences
    }

    /// Trims the history to the current limit; `delete` also removes the items' image files.
    func execute() {
        let items = store.fetchAll()
        for item in items.dropFirst(preferences.historyLimit) {
            store.delete(item)
        }
    }
}
