import AppKit
import XCTest
@testable import SpeakMore

final class ClipboardControllerTests: XCTestCase {
    func testClipboardSnapshotRestoresString() {
        let pasteboard = NSPasteboard.withUniqueName()
        pasteboard.clearContents()
        pasteboard.setString("original", forType: .string)
        let controller = ClipboardController(pasteboard: pasteboard)

        let snapshot = controller.snapshot()
        controller.writeText("replacement")
        XCTAssertEqual(pasteboard.string(forType: .string), "replacement")

        controller.restore(snapshot)
        XCTAssertEqual(pasteboard.string(forType: .string), "original")
    }

    func testClipboardSnapshotRestoresCustomData() {
        let pasteboard = NSPasteboard.withUniqueName()
        pasteboard.clearContents()
        let customType = NSPasteboard.PasteboardType("com.typeless.tests.custom")
        let originalData = Data([0x54, 0x59, 0x50, 0x45])
        let item = NSPasteboardItem()
        item.setData(originalData, forType: customType)
        pasteboard.writeObjects([item])
        let controller = ClipboardController(pasteboard: pasteboard)

        let snapshot = controller.snapshot()
        controller.writeText("replacement")
        XCTAssertEqual(pasteboard.string(forType: .string), "replacement")

        controller.restore(snapshot)
        XCTAssertEqual(pasteboard.pasteboardItems?.count, 1)
        XCTAssertEqual(pasteboard.pasteboardItems?.first?.data(forType: customType), originalData)
        XCTAssertNil(pasteboard.string(forType: .string))
    }

    func testClipboardSnapshotRestoresEmptyPasteboard() {
        let pasteboard = NSPasteboard.withUniqueName()
        pasteboard.clearContents()
        let controller = ClipboardController(pasteboard: pasteboard)

        let snapshot = controller.snapshot()
        controller.writeText("replacement")

        controller.restore(snapshot)
        XCTAssertEqual(pasteboard.pasteboardItems?.count ?? 0, 0)
        XCTAssertNil(pasteboard.string(forType: .string))
    }

    func testRestoreSkipsWhenPasteboardChangedSinceStaging() {
        let pasteboard = NSPasteboard.withUniqueName()
        pasteboard.clearContents()
        pasteboard.setString("original", forType: .string)
        let controller = ClipboardController(pasteboard: pasteboard)

        let snapshot = controller.snapshot()
        let stagedChangeCount = controller.writeTextReturningChangeCount("staged")
        pasteboard.clearContents()
        pasteboard.setString("external", forType: .string)

        let didRestore = controller.restore(snapshot, ifChangeCountIs: stagedChangeCount)

        XCTAssertFalse(didRestore)
        XCTAssertEqual(pasteboard.string(forType: .string), "external")
    }
}
