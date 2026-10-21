import AppKit
@testable import ClipboardManager
import XCTest

@MainActor
final class ImageIngestionServiceTests: XCTestCase {
    private var imageDirectory: URL!
    private var sut: ImageIngestionService!

    override func setUp() async throws {
        imageDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ImageIngestionServiceTests-\(UUID().uuidString)")
        sut = ImageIngestionService(imageFileStore: ImageFileStore(directoryURL: imageDirectory))
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: imageDirectory)
        sut = nil
        imageDirectory = nil
    }

    func test_completion_runsOnMainThread() throws {
        let expectation = expectation(description: "item delivered")
        let data = try makePNG(red: 1)
        sut.ingest(.image(data: data, pasteboardType: "public.png")) { item in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertEqual(item.type, .image)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)
    }

    func test_itemsAreDeliveredInCaptureOrder() throws {
        let expectation = expectation(description: "all items delivered")
        expectation.expectedFulfillmentCount = 3
        var delivered: [ClipboardItem] = []
        let captures: [ClipboardCapture] = try [
            .image(data: makePNG(red: 0.2), pasteboardType: "public.png"),
            .text("between"),
            .image(data: makePNG(red: 0.8), pasteboardType: "public.png")
        ]
        for capture in captures {
            sut.ingest(capture) { item in
                delivered.append(item)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 5)
        XCTAssertEqual(delivered.map(\.type), [.image, .text, .image])
        XCTAssertEqual(delivered[1].content, "between")
    }

    func test_invalidImage_producesNoItem() {
        let expectation = expectation(description: "no item")
        expectation.isInverted = true
        sut.ingest(.image(data: Data([0x00, 0x01, 0x02]), pasteboardType: "public.png")) { _ in
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    private func makePNG(red: CGFloat) throws -> Data {
        let rep = try XCTUnwrap(NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: 2, pixelsHigh: 2, bitsPerSample: 8, samplesPerPixel: 4,
            hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        ))
        rep.setColor(NSColor(red: red, green: 0, blue: 0, alpha: 1), atX: 0, y: 0)
        return try XCTUnwrap(rep.representation(using: .png, properties: [:]))
    }
}
