import XCTest
@testable import ClipboardManager

final class HotkeyManagerTests: XCTestCase {
    func test_mockHotkey_invokesCallbackOnTrigger() {
        let mock = MockHotkey()
        let expectation = expectation(description: "hotkey triggered")
        mock.onHotkeyTriggered = { expectation.fulfill() }
        mock.register()
        mock.trigger()
        wait(for: [expectation], timeout: 0.1)
        XCTAssertEqual(mock.registerCalls, 1)
    }

    func test_realHotkeyManager_canRegisterUnregisterWithoutCrash() {
        let sut = HotkeyManager()
        sut.register()
        sut.unregister()
    }
}

final class LaunchAtLoginServiceTests: XCTestCase {
    func test_mockLaunchAtLogin_enableSetsEnabled() throws {
        let mock = MockLaunchAtLogin()
        try mock.enable()
        XCTAssertTrue(mock.isEnabled)
        XCTAssertEqual(mock.enableCalls, 1)
    }

    func test_mockLaunchAtLogin_disableClearsEnabled() throws {
        let mock = MockLaunchAtLogin()
        try mock.enable()
        try mock.disable()
        XCTAssertFalse(mock.isEnabled)
    }

    func test_mockLaunchAtLogin_enablePropagatesError() {
        let mock = MockLaunchAtLogin()
        mock.enableError = NSError(domain: "test", code: 1)
        XCTAssertThrowsError(try mock.enable())
        XCTAssertFalse(mock.isEnabled)
    }
}
