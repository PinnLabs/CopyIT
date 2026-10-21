import XCTest
@testable import ClipboardManager

final class UserDefaultsPreferencesTests: XCTestCase {
    private func makeDefaults() throws -> UserDefaults {
        let suite = "UserDefaultsPreferencesTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
        return defaults
    }

    func test_historyLimit_defaultsTo50() throws {
        let sut = UserDefaultsPreferences(defaults: try makeDefaults())
        XCTAssertEqual(sut.historyLimit, 50)
    }

    func test_historyLimit_readsSavedValue() throws {
        let defaults = try makeDefaults()
        UserDefaultsPreferences(defaults: defaults).historyLimit = 200
        XCTAssertEqual(UserDefaultsPreferences(defaults: defaults).historyLimit, 200)
    }

    func test_historyLimit_invalidStoredValue_fallsBackToDefault() throws {
        let defaults = try makeDefaults()
        defaults.set(37, forKey: UserDefaultsPreferences.historyLimitKey)
        XCTAssertEqual(UserDefaultsPreferences(defaults: defaults).historyLimit, 50)
    }
}
