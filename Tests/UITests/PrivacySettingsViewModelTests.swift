import XCTest
@testable import ClipboardManager

@MainActor
final class PrivacySettingsViewModelTests: XCTestCase {
    private var store: MockClipboardStore!
    private var preferences: MockPreferences!
    private var ignoredApps: MockIgnoredApps!
    private var appInfo: MockAppInfo!
    private var sut: PrivacySettingsViewModel!

    override func setUp() async throws {
        store = MockClipboardStore()
        preferences = MockPreferences()
        ignoredApps = MockIgnoredApps(bundleIdentifiers: ["com.b.app", "com.a.app"])
        appInfo = MockAppInfo()
        appInfo.names = ["com.a.app": "Alpha", "com.b.app": "Bravo", "com.c.app": "Charlie"]
        sut = PrivacySettingsViewModel(
            preferences: preferences,
            ignoredApps: ignoredApps,
            appInfo: appInfo,
            pruneExpiredItemsUseCase: PruneExpiredItemsUseCase(store: store, preferences: preferences)
        )
    }

    override func tearDown() async throws {
        sut = nil
        appInfo = nil
        ignoredApps = nil
        preferences = nil
        store = nil
    }

    func test_ignoredApps_areSortedByName() {
        XCTAssertEqual(sut.ignoredApps.map(\.name), ["Alpha", "Bravo"])
    }

    func test_addApp_appendsAndSelectsIt() {
        sut.addApp(bundleIdentifier: "com.c.app")
        XCTAssertEqual(ignoredApps.bundleIdentifiers, ["com.b.app", "com.a.app", "com.c.app"])
        XCTAssertEqual(sut.ignoredApps.map(\.name), ["Alpha", "Bravo", "Charlie"])
        XCTAssertEqual(sut.selectedAppID, "com.c.app")
    }

    func test_removeSelectedApp_removesIt() {
        sut.selectedAppID = "com.a.app"
        sut.removeSelectedApp()
        XCTAssertEqual(ignoredApps.bundleIdentifiers, ["com.b.app"])
        XCTAssertNil(sut.selectedAppID)
    }

    func test_removeWithoutSelection_doesNothing() {
        sut.removeSelectedApp()
        XCTAssertEqual(ignoredApps.bundleIdentifiers.count, 2)
    }

    func test_restoreDefaults_callsProvider() {
        sut.restoreDefaultIgnoredApps()
        XCTAssertEqual(ignoredApps.restoreDefaultsCalls, 1)
    }

    func test_changingRetention_savesAndPrunes() {
        store.savedItems = [ClipboardItem(content: "old", type: .text, createdAt: Date(timeIntervalSince1970: 0))]
        sut.retention = .oneDay
        XCTAssertEqual(preferences.retention, .oneDay)
        XCTAssertTrue(store.savedItems.isEmpty)
    }

    func test_clearsHistoryOnQuit_isSaved() {
        sut.clearsHistoryOnQuit = true
        XCTAssertTrue(preferences.clearsHistoryOnQuit)
    }
}
