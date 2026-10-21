import Foundation

final class UserDefaultsPreferences: PreferencesStoring {
    static let historyLimitKey = "com.copyit.preferences.historyLimit"
    static let retentionKey = "com.copyit.preferences.retention"
    static let clearsHistoryOnQuitKey = "com.copyit.preferences.clearsHistoryOnQuit"

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

    var retention: HistoryRetention {
        get { defaults.string(forKey: Self.retentionKey).flatMap(HistoryRetention.init(rawValue:)) ?? .forever }
        set { defaults.set(newValue.rawValue, forKey: Self.retentionKey) }
    }

    var clearsHistoryOnQuit: Bool {
        get { defaults.bool(forKey: Self.clearsHistoryOnQuitKey) }
        set { defaults.set(newValue, forKey: Self.clearsHistoryOnQuitKey) }
    }
}
