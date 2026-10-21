import Foundation

protocol ClipboardMonitoring: AnyObject {
    var onNewItem: ((ClipboardCapture) -> Void)? { get set }
    func startMonitoring()
    func stopMonitoring()
    var isPaused: Bool { get }
    /// Pass `nil` to pause until `resume()` is called.
    func pause(until date: Date?)
    func resume()
}
