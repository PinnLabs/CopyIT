import XCTest
@testable import ClipboardManager

final class ClipboardMonitorTests: XCTestCase {
    func test_monitor_canBeStartedAndStopped() {
        let sut = ClipboardMonitor(pollInterval: 0.1)
        sut.startMonitoring()
        sut.stopMonitoring()
    }

    func test_itemFactory_detectsURLType() {
        let item = ClipboardItem.from(pasteboardString: "https://example.com")
        XCTAssertEqual(item.type, .url)
    }

    func test_itemFactory_detectsTextType() {
        let item = ClipboardItem.from(pasteboardString: "plain text")
        XCTAssertEqual(item.type, .text)
    }

    func test_itemFactory_returnsUnknownForEmptyString() {
        let item = ClipboardItem.from(pasteboardString: "   ")
        XCTAssertEqual(item.type, .unknown)
    }
}
