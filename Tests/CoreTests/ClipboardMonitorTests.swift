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

    func test_imageCapture_preservesImagePayload() {
        let data = Data([0x89, 0x50, 0x4E, 0x47])
        let capture = ClipboardCapture.image(
            data: data,
            pasteboardType: NSPasteboard.PasteboardType.png.rawValue
        )

        XCTAssertEqual(
            capture,
            .image(data: data, pasteboardType: NSPasteboard.PasteboardType.png.rawValue)
        )
    }

    // MARK: - Ignored pasteboard types

    private let concealed = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")
    private let transient = NSPasteboard.PasteboardType("org.nspasteboard.TransientType")

    private func makeSUT(
        frontmost: String? = nil,
        ignored: [String] = []
    ) -> (ClipboardMonitor, NSPasteboard, () -> [ClipboardCapture]) {
        let pasteboard = NSPasteboard.withUniqueName()
        addTeardownBlock { pasteboard.releaseGlobally() }
        let sut = ClipboardMonitor(
            pasteboard: pasteboard,
            ignoredApps: MockIgnoredApps(bundleIdentifiers: ignored),
            frontmostApp: MockFrontmostApp(frontmostBundleIdentifier: frontmost)
        )
        var captures: [ClipboardCapture] = []
        sut.onNewItem = { captures.append($0) }
        return (sut, pasteboard, { captures })
    }

    private func write(_ text: String, markedAs marker: NSPasteboard.PasteboardType?, to pasteboard: NSPasteboard) {
        pasteboard.clearContents()
        pasteboard.declareTypes([.string] + (marker.map { [$0] } ?? []), owner: nil)
        pasteboard.setString(text, forType: .string)
        if let marker { pasteboard.setData(Data(), forType: marker) }
    }

    func test_concealedText_isIgnored() {
        let (sut, pasteboard, captures) = makeSUT()
        write("secret", markedAs: concealed, to: pasteboard)
        sut.checkForClipboardChanges()
        XCTAssertTrue(captures().isEmpty)
    }

    func test_transientText_isIgnored() {
        let (sut, pasteboard, captures) = makeSUT()
        write("temp", markedAs: transient, to: pasteboard)
        sut.checkForClipboardChanges()
        XCTAssertTrue(captures().isEmpty)
    }

    func test_concealedImage_isIgnored() {
        let (sut, pasteboard, captures) = makeSUT()
        pasteboard.clearContents()
        pasteboard.declareTypes([.png, concealed], owner: nil)
        pasteboard.setData(Data([0x89, 0x50, 0x4E, 0x47]), forType: .png)
        pasteboard.setData(Data(), forType: concealed)
        sut.checkForClipboardChanges()
        XCTAssertTrue(captures().isEmpty)
    }

    func test_plainText_isCaptured() {
        let (sut, pasteboard, captures) = makeSUT()
        write("hello", markedAs: nil, to: pasteboard)
        sut.checkForClipboardChanges()
        XCTAssertEqual(captures(), [.text("hello")])
    }

    func test_plainTextAfterIgnoredItem_isCaptured() {
        let (sut, pasteboard, captures) = makeSUT()
        write("secret", markedAs: concealed, to: pasteboard)
        sut.checkForClipboardChanges()
        write("hello", markedAs: nil, to: pasteboard)
        sut.checkForClipboardChanges()
        XCTAssertEqual(captures(), [.text("hello")])
    }

    // MARK: - Ignored apps

    func test_itemFromIgnoredApp_isIgnored() {
        let (sut, pasteboard, captures) = makeSUT(frontmost: "com.bitwarden.desktop", ignored: ["com.bitwarden.desktop"])
        write("secret", markedAs: nil, to: pasteboard)
        sut.checkForClipboardChanges()
        XCTAssertTrue(captures().isEmpty)
    }

    func test_itemFromNonIgnoredApp_isCaptured() {
        let (sut, pasteboard, captures) = makeSUT(frontmost: "com.apple.Safari", ignored: ["com.bitwarden.desktop"])
        write("hello", markedAs: nil, to: pasteboard)
        sut.checkForClipboardChanges()
        XCTAssertEqual(captures(), [.text("hello")])
    }

    func test_noFrontmostApp_doesNotBlockCapture() {
        let (sut, pasteboard, captures) = makeSUT(frontmost: nil, ignored: ["com.bitwarden.desktop"])
        write("hello", markedAs: nil, to: pasteboard)
        sut.checkForClipboardChanges()
        XCTAssertEqual(captures(), [.text("hello")])
    }
}
