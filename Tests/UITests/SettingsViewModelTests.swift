import XCTest
@testable import ClipboardManager

@MainActor
final class SettingsViewModelTests: XCTestCase {
    private var store: MockClipboardStore!
    private var preferences: MockPreferences!
    private var launchAtLogin: MockLaunchAtLogin!
    private var sut: SettingsViewModel!

    override func setUp() async throws {
        store = MockClipboardStore()
        preferences = MockPreferences(historyLimit: 50)
        launchAtLogin = MockLaunchAtLogin()
        sut = SettingsViewModel(
            preferences: preferences,
            launchAtLogin: launchAtLogin,
            applyHistoryLimitUseCase: ApplyHistoryLimitUseCase(store: store, preferences: preferences)
        )
    }

    override func tearDown() async throws {
        sut = nil
        launchAtLogin = nil
        preferences = nil
        store = nil
    }

    func test_changingHistoryLimit_savesAndTrimsHistory() {
        store.savedItems = (0..<30).map { ClipboardItem(content: "item-\($0)", type: .text) }
        sut.historyLimit = 25
        XCTAssertEqual(preferences.historyLimit, 25)
        XCTAssertEqual(store.savedItems.count, 25)
    }

    func test_toggleOn_callsEnable() {
        sut.setLaunchAtLogin(true)
        XCTAssertEqual(launchAtLogin.enableCalls, 1)
        XCTAssertTrue(sut.isLaunchAtLoginEnabled)
    }

    func test_toggleOff_callsDisable() throws {
        try launchAtLogin.enable()
        sut.refresh()
        sut.setLaunchAtLogin(false)
        XCTAssertEqual(launchAtLogin.disableCalls, 1)
        XCTAssertFalse(sut.isLaunchAtLoginEnabled)
    }

    func test_toggleError_revertsToRealState() {
        launchAtLogin.enableError = NSError(domain: "test", code: 1)
        sut.setLaunchAtLogin(true)
        XCTAssertEqual(launchAtLogin.enableCalls, 1)
        XCTAssertFalse(sut.isLaunchAtLoginEnabled)
    }

    func test_requiresApproval_isExposed() {
        launchAtLogin.requiresApproval = true
        sut.refresh()
        XCTAssertTrue(sut.launchAtLoginRequiresApproval)
    }
}
