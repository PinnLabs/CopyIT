import XCTest
import Carbon.HIToolbox
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

    func test_register_twiceThenUnregister_clearsState() {
        let sut = HotkeyManager()
        sut.register()
        sut.register()
        sut.unregister()
        XCTAssertFalse(sut.isRegistered)
    }

    func test_unregister_withoutRegister_doesNotCrash() {
        let sut = HotkeyManager()
        sut.unregister()
        XCTAssertFalse(sut.isRegistered)
    }

    func test_handleHotKeyPressed_withMatchingID_triggersCallback() {
        let sut = HotkeyManager()
        let expectation = expectation(description: "hotkey triggered")
        sut.onHotkeyTriggered = { expectation.fulfill() }
        let handled = sut.handleHotKeyPressed(id: EventHotKeyID(signature: HotkeyManager.signature, id: HotkeyManager.hotKeyID))
        XCTAssertTrue(handled)
        wait(for: [expectation], timeout: 1)
    }

    func test_handleHotKeyPressed_withOtherIDOrSignature_doesNotTrigger() {
        let sut = HotkeyManager()
        let expectation = expectation(description: "hotkey not triggered")
        expectation.isInverted = true
        sut.onHotkeyTriggered = { expectation.fulfill() }
        XCTAssertFalse(sut.handleHotKeyPressed(id: EventHotKeyID(signature: HotkeyManager.signature, id: 2)))
        XCTAssertFalse(sut.handleHotKeyPressed(id: EventHotKeyID(signature: 0x5858_5858, id: HotkeyManager.hotKeyID)))
        wait(for: [expectation], timeout: 0.2)
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
