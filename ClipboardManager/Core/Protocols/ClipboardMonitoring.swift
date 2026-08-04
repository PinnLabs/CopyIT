import Foundation

protocol ClipboardMonitoring: AnyObject {
    var onNewItem: ((ClipboardCapture) -> Void)? { get set }
    func startMonitoring()
    func stopMonitoring()
}
