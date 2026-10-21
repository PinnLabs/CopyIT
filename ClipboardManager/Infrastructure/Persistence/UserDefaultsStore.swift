import Foundation

final class UserDefaultsStore: ClipboardStoring {
    private static let storageKey = "com.copyit.clipboard.history"

    private let defaults: UserDefaults
    private let imageFileStore: ImageFileStore
    private let preferences: PreferencesStoring
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(
        defaults: UserDefaults = .standard,
        imageFileStore: ImageFileStore = ImageFileStore(),
        preferences: PreferencesStoring? = nil
    ) {
        self.defaults = defaults
        self.imageFileStore = imageFileStore
        self.preferences = preferences ?? UserDefaultsPreferences(defaults: defaults)
    }

    func save(_ item: ClipboardItem) {
        var current = fetchAll()
        for replacedItem in current.filter({ $0.hasSamePayload(as: item) }) {
            imageFileStore.delete(
                imageFileName: replacedItem.imageFileName == item.imageFileName ? nil : replacedItem.imageFileName,
                thumbnailFileName: replacedItem.thumbnailFileName == item.thumbnailFileName ? nil : replacedItem.thumbnailFileName
            )
        }
        current.removeAll { $0.hasSamePayload(as: item) }
        current.insert(item, at: 0)
        enforceImageBudget(in: &current)

        let limit = preferences.historyLimit
        if current.count > limit {
            for removedItem in current.dropFirst(limit) {
                deleteImageFiles(for: removedItem)
            }
            current = Array(current.prefix(limit))
        }
        persist(current)
    }

    func fetchAll() -> [ClipboardItem] {
        guard let data = defaults.data(forKey: Self.storageKey),
              let decoded = try? decoder.decode([ClipboardItem].self, from: data) else { return [] }

        var didMigrate = false
        var migrated = decoded.compactMap { item -> ClipboardItem? in
            guard item.type == .image, item.imageFileName == nil, item.legacyImageData != nil else {
                return item
            }
            didMigrate = true
            return prepareForPersistence(item)
        }
        if didMigrate {
            enforceImageBudget(in: &migrated)
            persist(migrated)
        }

        return migrated.map(resolveThumbnail)
    }

    func delete(_ item: ClipboardItem) {
        var current = fetchAll()
        current.removeAll { $0.id == item.id }
        deleteImageFiles(for: item)
        persist(current)
    }

    func clear() {
        defaults.removeObject(forKey: Self.storageKey)
        imageFileStore.clear()
    }

    private func persist(_ items: [ClipboardItem]) {
        guard let data = try? encoder.encode(items) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }

    private func prepareForPersistence(_ item: ClipboardItem) -> ClipboardItem? {
        guard item.type == .image else { return item }
        guard let imageData = item.legacyImageData,
              let pasteboardType = item.imagePasteboardType,
              let stored = imageFileStore.store(data: imageData, pasteboardType: pasteboardType) else {
            return item.imageFileName == nil ? nil : item
        }

        return item.storedImage(
            imageFileName: stored.imageFileName,
            imageDigest: stored.digest,
            thumbnailFileName: stored.thumbnailFileName,
            thumbnailFileURL: imageFileStore.thumbnailURL(fileName: stored.thumbnailFileName)
        )
    }

    private func resolveThumbnail(for item: ClipboardItem) -> ClipboardItem {
        guard item.type == .image else { return item }
        return item.resolvingThumbnail(
            at: imageFileStore.thumbnailURL(fileName: item.thumbnailFileName)
        )
    }

    private func enforceImageBudget(in items: inout [ClipboardItem]) {
        func storedImageBytes() -> Int {
            items.reduce(into: 0) { total, item in
                guard let fileName = item.imageFileName else { return }
                total += imageFileStore.fileSize(fileName: fileName)
            }
        }

        while storedImageBytes() > ImageFileStore.maxTotalBytes,
              let oldestImageIndex = items.lastIndex(where: { $0.type == .image }) {
            let removedItem = items.remove(at: oldestImageIndex)
            deleteImageFiles(for: removedItem)
        }
    }

    private func deleteImageFiles(for item: ClipboardItem) {
        guard item.type == .image else { return }
        imageFileStore.delete(
            imageFileName: item.imageFileName,
            thumbnailFileName: item.thumbnailFileName
        )
    }
}
