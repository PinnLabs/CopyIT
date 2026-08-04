import Foundation

protocol ClipboardMonitoring: AnyObject {
    var onNewItem: ((ClipboardItem) -> Void)? { get set }
    func startMonitoring()
    func stopMonitoring()
}
