import Foundation

protocol PreferencesStoring: AnyObject {
    var historyLimit: Int { get set }
    /// Defaults to `.forever`.
    var retention: HistoryRetention { get set }
    /// Defaults to `false`.
    var clearsHistoryOnQuit: Bool { get set }
}

enum HistoryLimit {
    static let defaultValue = 50
    static let options = [25, 50, 100, 200]
}
