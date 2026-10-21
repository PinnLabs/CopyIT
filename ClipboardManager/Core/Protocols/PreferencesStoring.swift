import Foundation

protocol PreferencesStoring: AnyObject {
    var historyLimit: Int { get set }
}

enum HistoryLimit {
    static let defaultValue = 50
    static let options = [25, 50, 100, 200]
}
