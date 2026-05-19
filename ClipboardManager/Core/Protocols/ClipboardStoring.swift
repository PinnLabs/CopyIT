import Foundation

protocol ClipboardStoring: AnyObject {
    func save(_ item: ClipboardItem)
    func fetchAll() -> [ClipboardItem]
    func delete(_ item: ClipboardItem)
    func clear()
}
