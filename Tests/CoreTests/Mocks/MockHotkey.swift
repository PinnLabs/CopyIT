import Foundation
@testable import ClipboardManager

final class MockHotkey: HotkeyRegistering {
    var onHotkeyTriggered: (() -> Void)?
    private(set) var registerCalls = 0
    private(set) var unregisterCalls = 0

    func register() { registerCalls += 1 }
    func unregister() { unregisterCalls += 1 }

    func trigger() { onHotkeyTriggered?() }
}

final class MockLaunchAtLogin: LaunchAtLoginManaging {
    var isEnabled: Bool = false
    private(set) var enableCalls = 0
    private(set) var disableCalls = 0
    var enableError: Error?
    var disableError: Error?

    func enable() throws {
        enableCalls += 1
        if let error = enableError { throw error }
        isEnabled = true
    }

    func disable() throws {
        disableCalls += 1
        if let error = disableError { throw error }
        isEnabled = false
    }
}
