import Foundation
@testable import ClipboardManager

final class MockPreferences: PreferencesStoring {
    var historyLimit: Int

    init(historyLimit: Int = 50) {
        self.historyLimit = historyLimit
    }
}
