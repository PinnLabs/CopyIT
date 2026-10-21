import AppKit
@testable import ClipboardManager

final class MockIgnoredApps: IgnoredAppsProviding {
    var bundleIdentifiers: [String]

    init(bundleIdentifiers: [String] = []) {
        self.bundleIdentifiers = bundleIdentifiers
    }

    func isIgnored(bundleIdentifier: String) -> Bool {
        bundleIdentifiers.contains(bundleIdentifier)
    }

    private(set) var restoreDefaultsCalls = 0
    func restoreDefaults() {
        restoreDefaultsCalls += 1
        bundleIdentifiers = UserDefaultsIgnoredApps.defaultBundleIdentifiers
    }
}

struct MockFrontmostApp: FrontmostAppProviding {
    var frontmostBundleIdentifier: String?
}

final class MockAppInfo: AppInfoProviding {
    var names: [String: String] = [:]

    func appInfo(bundleIdentifier: String) -> (name: String, icon: NSImage?) {
        (names[bundleIdentifier] ?? bundleIdentifier, nil)
    }
}
