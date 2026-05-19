import Foundation

final class UserDefaultsStore: ClipboardStoring {
    private static let storageKey = "com.copyit.clipboard.history"
    static let maxHistoryCount = 50

    private let defaults: UserDefaults
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func save(_ item: ClipboardItem) {
        var current = fetchAll()
        current.removeAll { $0.content == item.content }
        current.insert(item, at: 0)
        if current.count > Self.maxHistoryCount {
            current = Array(current.prefix(Self.maxHistoryCount))
        }
        persist(current)
    }

    func fetchAll() -> [ClipboardItem] {
        guard let data = defaults.data(forKey: Self.storageKey) else { return [] }
        guard let decoded = try? decoder.decode([ClipboardItem].self, from: data) else { return [] }
        return decoded
    }

    func delete(_ item: ClipboardItem) {
        var current = fetchAll()
        current.removeAll { $0.id == item.id }
        persist(current)
    }

    func clear() {
        defaults.removeObject(forKey: Self.storageKey)
    }

    private func persist(_ items: [ClipboardItem]) {
        guard let data = try? encoder.encode(items) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }
}
