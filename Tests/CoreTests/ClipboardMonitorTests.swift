import XCTest
import AppKit
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

    func test_imageItemFactory_preservesImagePayload() {
        let data = Data([0x89, 0x50, 0x4E, 0x47])
        let item = ClipboardItem.from(
            imageData: data,
            pasteboardType: NSPasteboard.PasteboardType.png.rawValue
        )

        XCTAssertEqual(item.type, .image)
        XCTAssertEqual(item.imageData, data)
        XCTAssertEqual(item.imagePasteboardType, NSPasteboard.PasteboardType.png.rawValue)
    }
}
