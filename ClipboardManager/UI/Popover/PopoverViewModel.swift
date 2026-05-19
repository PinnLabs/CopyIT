import Foundation
import Observation

@MainActor
@Observable
final class PopoverViewModel {
    private(set) var items: [ClipboardItem] = []
    private(set) var filteredItems: [ClipboardItem] = []
    private(set) var selectedIndex: Int = 0
    var searchText: String = "" {
        didSet { applyFilter() }
    }

    private let fetchUseCase: FetchHistoryUseCase
    private let copyUseCase: CopyItemUseCase
    private let deleteUseCase: DeleteItemUseCase
    private let clearUseCase: ClearHistoryUseCase

    init(
        fetchUseCase: FetchHistoryUseCase,
        copyUseCase: CopyItemUseCase,
        deleteUseCase: DeleteItemUseCase,
        clearUseCase: ClearHistoryUseCase
    ) {
        self.fetchUseCase = fetchUseCase
        self.copyUseCase = copyUseCase
        self.deleteUseCase = deleteUseCase
        self.clearUseCase = clearUseCase
    }

    func refresh() {
        items = fetchUseCase.execute()
        applyFilter()
    }

    func copy(_ item: ClipboardItem) {
        copyUseCase.execute(item: item)
    }

    func delete(_ item: ClipboardItem) {
        deleteUseCase.execute(item: item)
        refresh()
    }

    func clearAll() {
        clearUseCase.execute()
        refresh()
    }

    func moveSelection(by offset: Int) {
        guard !filteredItems.isEmpty else { return }
        let next = selectedIndex + offset
        selectedIndex = max(0, min(filteredItems.count - 1, next))
    }

    func copySelected() {
        guard filteredItems.indices.contains(selectedIndex) else { return }
        copy(filteredItems[selectedIndex])
    }

    func deleteSelected() {
        guard filteredItems.indices.contains(selectedIndex) else { return }
        let target = filteredItems[selectedIndex]
        delete(target)
        selectedIndex = min(selectedIndex, max(0, filteredItems.count - 1))
    }

    func isSelected(_ item: ClipboardItem) -> Bool {
        guard filteredItems.indices.contains(selectedIndex) else { return false }
        return filteredItems[selectedIndex].id == item.id
    }

    private func applyFilter() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            filteredItems = items
        } else {
            filteredItems = items.filter {
                $0.content.localizedCaseInsensitiveContains(query)
            }
        }
        selectedIndex = filteredItems.isEmpty ? 0 : min(selectedIndex, filteredItems.count - 1)
    }
}
