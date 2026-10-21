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

    func test_addingExistingID_doesNotDuplicate() {
        let sut = UserDefaultsIgnoredApps(defaults: makeDefaults())
        sut.bundleIdentifiers.append("com.example.app")
        sut.bundleIdentifiers.append("com.example.app")
        XCTAssertEqual(sut.bundleIdentifiers.filter { $0 == "com.example.app" }.count, 1)
        XCTAssertEqual(sut.bundleIdentifiers.count, UserDefaultsIgnoredApps.defaultBundleIdentifiers.count + 1)
    }

    func test_removingID_stopsIgnoringIt() {
        let sut = UserDefaultsIgnoredApps(defaults: makeDefaults())
        sut.bundleIdentifiers.removeAll { $0 == "com.bitwarden.desktop" }
        XCTAssertFalse(sut.isIgnored(bundleIdentifier: "com.bitwarden.desktop"))
    }

    func test_restoreDefaults_replacesCustomList() {
        let sut = UserDefaultsIgnoredApps(defaults: makeDefaults())
        sut.bundleIdentifiers = ["com.example.app"]
        sut.restoreDefaults()
        XCTAssertEqual(sut.bundleIdentifiers, UserDefaultsIgnoredApps.defaultBundleIdentifiers)
    }
}
