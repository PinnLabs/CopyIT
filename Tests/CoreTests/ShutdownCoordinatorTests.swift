import XCTest
@testable import ClipboardManager

final class ShutdownCoordinatorTests: XCTestCase {
    private var defaults: UserDefaults!
    private var store: MockClipboardStore!
    private var preferences: MockPreferences!
    private var sut: ShutdownCoordinator!

    override func setUpWithError() throws {
        let suite = "ShutdownCoordinatorTests.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        addTeardownBlock { [defaults] in defaults?.removePersistentDomain(forName: suite) }
        store = MockClipboardStore()
        store.savedItems = [ClipboardItem(content: "hello", type: .text)]
        preferences = MockPreferences()
        sut = ShutdownCoordinator(
            defaults: defaults,
            preferences: preferences,
            clearHistoryUseCase: ClearHistoryUseCase(store: store)
        )
    }

    func test_terminate_withPreferenceOn_clearsHistory() {
        preferences.clearsHistoryOnQuit = true
        sut.handleTerminate()
        XCTAssertTrue(store.clearCalled)
        XCTAssertFalse(defaults.bool(forKey: ShutdownCoordinator.pendingClearKey))
        XCTAssertTrue(defaults.bool(forKey: ShutdownCoordinator.didTerminateCleanlyKey))
    }

    func test_terminate_withPreferenceOff_keepsHistory() {
        sut.handleTerminate()
        XCTAssertFalse(store.clearCalled)
    }

    func test_launch_withPendingClearAndPreferenceOn_clearsHistory() {
        preferences.clearsHistoryOnQuit = true
        defaults.set(true, forKey: ShutdownCoordinator.pendingClearKey)
        defaults.set(true, forKey: ShutdownCoordinator.didTerminateCleanlyKey)
        sut.handleLaunch()
        XCTAssertTrue(store.clearCalled)
        XCTAssertFalse(defaults.bool(forKey: ShutdownCoordinator.pendingClearKey))
    }

    func test_launch_afterUncleanShutdownWithPreferenceOn_clearsHistory() {
        preferences.clearsHistoryOnQuit = true
        sut.handleLaunch()
        XCTAssertTrue(store.clearCalled)
    }

    func test_launch_afterCleanShutdown_keepsHistory() {
        preferences.clearsHistoryOnQuit = true
        defaults.set(true, forKey: ShutdownCoordinator.didTerminateCleanlyKey)
        sut.handleLaunch()
        XCTAssertFalse(store.clearCalled)
        XCTAssertFalse(defaults.bool(forKey: ShutdownCoordinator.didTerminateCleanlyKey))
    }

    func test_launch_withPreferenceOff_keepsHistory() {
        defaults.set(true, forKey: ShutdownCoordinator.pendingClearKey)
        sut.handleLaunch()
        XCTAssertFalse(store.clearCalled)
    }
}
