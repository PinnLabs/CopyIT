import XCTest
@testable import ClipboardManager

final class UserDefaultsIgnoredAppsTests: XCTestCase {
    private func makeDefaults() -> UserDefaults {
        let suite = "UserDefaultsIgnoredAppsTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
        return defaults
    }

    func test_withoutStoredKey_usesDefaultList() {
        let sut = UserDefaultsIgnoredApps(defaults: makeDefaults())
        XCTAssertEqual(sut.bundleIdentifiers, UserDefaultsIgnoredApps.defaultBundleIdentifiers)
        XCTAssertTrue(sut.isIgnored(bundleIdentifier: "com.apple.Passwords"))
    }

    func test_withStoredKey_usesStoredList() {
        let defaults = makeDefaults()
        defaults.set(["com.example.app"], forKey: UserDefaultsIgnoredApps.storageKey)
        let sut = UserDefaultsIgnoredApps(defaults: defaults)
        XCTAssertEqual(sut.bundleIdentifiers, ["com.example.app"])
        XCTAssertFalse(sut.isIgnored(bundleIdentifier: "com.apple.Passwords"))
    }
}
