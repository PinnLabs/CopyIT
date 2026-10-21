@testable import ClipboardManager
import XCTest

final class UserDefaultsPreferencesTests: XCTestCase {
    private func makeDefaults() throws -> UserDefaults {
        let suite = "UserDefaultsPreferencesTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
        return defaults
    }

    func test_historyLimit_defaultsTo50() throws {
        let sut = try UserDefaultsPreferences(defaults: makeDefaults())
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

    func test_retentionAndClearOnQuit_haveDefaults() throws {
        let sut = try UserDefaultsPreferences(defaults: makeDefaults())
        XCTAssertEqual(sut.retention, .forever)
        XCTAssertFalse(sut.clearsHistoryOnQuit)
    }

    func test_retentionAndClearOnQuit_readSavedValues() throws {
        let defaults = try makeDefaults()
        let writer = UserDefaultsPreferences(defaults: defaults)
        writer.retention = .thirtyDays
        writer.clearsHistoryOnQuit = true
        let sut = UserDefaultsPreferences(defaults: defaults)
        XCTAssertEqual(sut.retention, .thirtyDays)
        XCTAssertTrue(sut.clearsHistoryOnQuit)
    }

    func test_retention_invalidStoredValue_fallsBackToForever() throws {
        let defaults = try makeDefaults()
        defaults.set("fortnight", forKey: UserDefaultsPreferences.retentionKey)
        XCTAssertEqual(UserDefaultsPreferences(defaults: defaults).retention, .forever)
    }
}
