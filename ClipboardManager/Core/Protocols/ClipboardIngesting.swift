import Foundation

protocol ClipboardIngesting: AnyObject {
    /// Turns a capture into a history item off the main thread. `completion` runs on the main actor,
    /// in capture order, and is not called when the capture can't be turned into an item.
    func ingest(_ capture: ClipboardCapture, completion: @escaping @MainActor (ClipboardItem) -> Void)
}
