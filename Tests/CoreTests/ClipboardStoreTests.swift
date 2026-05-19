import XCTest
@testable import ClipboardManager

final class ClipboardStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var sut: UserDefaultsStore!
    private let suiteName = "ClipboardStoreTests.suite"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        sut = UserDefaultsStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        sut = nil
        defaults = nil
        super.tearDown()
    }

    func test_saveAndFetch_returnsSavedItems() {
        let item = ClipboardItem(content: "hello", type: .text)
        sut.save(item)
        XCTAssertEqual(sut.fetchAll().first?.content, "hello")
    }

    func test_delete_removesItem() {
        let item = ClipboardItem(content: "hello", type: .text)
        sut.save(item)
        sut.delete(item)
        XCTAssertTrue(sut.fetchAll().isEmpty)
    }

    func test_clear_emptiesStore() {
        sut.save(ClipboardItem(content: "a", type: .text))
        sut.save(ClipboardItem(content: "b", type: .text))
        sut.clear()
        XCTAssertTrue(sut.fetchAll().isEmpty)
    }

    func test_save_dedupesByContent() {
        sut.save(ClipboardItem(content: "x", type: .text))
        sut.save(ClipboardItem(content: "x", type: .text))
        XCTAssertEqual(sut.fetchAll().count, 1)
    }

    func test_save_capsAt50Items() {
        for index in 0..<60 {
            sut.save(ClipboardItem(content: "item-\(index)", type: .text))
        }
        XCTAssertEqual(sut.fetchAll().count, UserDefaultsStore.maxHistoryCount)
    }
}
