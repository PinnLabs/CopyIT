@testable import ClipboardManager
import Foundation

final class MockPreferences: PreferencesStoring {
    var historyLimit: Int
    var retention: HistoryRetention = .forever
    var clearsHistoryOnQuit = false

    init(historyLimit: Int = 50) {
        self.historyLimit = historyLimit
    }
}
