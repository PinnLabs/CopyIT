import Foundation

protocol ClipboardMonitoring: AnyObject {
    var onNewItem: ((String) -> Void)? { get set }
    func startMonitoring()
    func stopMonitoring()
}
