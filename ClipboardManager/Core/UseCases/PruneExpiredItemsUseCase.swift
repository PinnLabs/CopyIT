import Foundation

final class PruneExpiredItemsUseCase {
    private let store: ClipboardStoring
    private let preferences: PreferencesStoring
    private let now: () -> Date

    init(store: ClipboardStoring, preferences: PreferencesStoring, now: @escaping () -> Date = Date.init) {
        self.store = store
        self.preferences = preferences
        self.now = now
    }

    /// Deletes items older than the retention period; `delete` also removes their image files.
    func execute() {
        guard let maxAge = preferences.retention.maxAge else { return }
        let cutoff = now().addingTimeInterval(-maxAge)
        for item in store.fetchAll() where item.createdAt < cutoff {
            store.delete(item)
        }
    }
}
