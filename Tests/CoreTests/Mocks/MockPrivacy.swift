import Foundation
@testable import ClipboardManager

final class MockIgnoredApps: IgnoredAppsProviding {
    var bundleIdentifiers: [String]

    init(bundleIdentifiers: [String] = []) {
        self.bundleIdentifiers = bundleIdentifiers
    }

    func isIgnored(bundleIdentifier: String) -> Bool {
        bundleIdentifiers.contains(bundleIdentifier)
    }
}

struct MockFrontmostApp: FrontmostAppProviding {
    var frontmostBundleIdentifier: String?
}
