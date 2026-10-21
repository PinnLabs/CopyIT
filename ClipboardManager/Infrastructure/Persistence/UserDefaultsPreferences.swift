import Foundation

final class UserDefaultsPreferences: PreferencesStoring {
    static let historyLimitKey = "com.copyit.preferences.historyLimit"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var historyLimit: Int {
        get {
            let stored = defaults.integer(forKey: Self.historyLimitKey)
            return HistoryLimit.options.contains(stored) ? stored : HistoryLimit.defaultValue
        }
        set {
            let value = HistoryLimit.options.contains(newValue) ? newValue : HistoryLimit.defaultValue
            defaults.set(value, forKey: Self.historyLimitKey)
        }
    }
}
