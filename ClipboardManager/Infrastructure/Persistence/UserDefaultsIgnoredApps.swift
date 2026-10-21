import Foundation

final class UserDefaultsIgnoredApps: IgnoredAppsProviding {
    static let storageKey = "com.copyit.privacy.ignoredApps"
    static let defaultBundleIdentifiers = [
        "com.apple.keychainaccess",
        "com.apple.Passwords",
        "com.1password.1password",
        "com.agilebits.onepassword7",
        "com.bitwarden.desktop"
    ]

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var bundleIdentifiers: [String] {
        get { defaults.stringArray(forKey: Self.storageKey) ?? Self.defaultBundleIdentifiers }
        set {
            var seen = Set<String>()
            defaults.set(newValue.filter { seen.insert($0).inserted }, forKey: Self.storageKey)
        }
    }

    func isIgnored(bundleIdentifier: String) -> Bool {
        bundleIdentifiers.contains(bundleIdentifier)
    }

    func restoreDefaults() {
        defaults.removeObject(forKey: Self.storageKey)
    }
}
