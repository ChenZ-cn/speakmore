import AppKit
import XCTest
@testable import SpeakMore

@MainActor
final class PasteControllerTests: XCTestCase {
    func testScheduledRestoreSkipsWhenPasteboardChangedAfterStaging() {
        let pasteboard = NSPasteboard.withUniqueName()
        pasteboard.clearContents()
        pasteboard.setString("original", forType: .string)
        let clipboard = ClipboardController(pasteboard: pasteboard)
        var scheduledWorkItems: [DispatchWorkItem] = []
        let controller = PasteController(
            clipboard: clipboard,
            keyboardShortcutPoster: {},
            accessibilityPermissionChecker: { true },
            restoreScheduler: { scheduledWorkItems.append($0) }
        )

        XCTAssertNoThrow(try controller.paste(text: "staged"))
        pasteboard.clearContents()
        pasteboard.setString("external", forType: .string)
        scheduledWorkItems.first?.perform()

        XCTAssertEqual(pasteboard.string(forType: .string), "external")
    }

    func testNewPasteCancelsEarlierPendingRestore() {
        let pasteboard = NSPasteboard.withUniqueName()
        pasteboard.clearContents()
        pasteboard.setString("original", forType: .string)
        let clipboard = ClipboardController(pasteboard: pasteboard)
        var scheduledWorkItems: [DispatchWorkItem] = []
        let controller = PasteController(
            clipboard: clipboard,
            keyboardShortcutPoster: {},
            accessibilityPermissionChecker: { true },
            restoreScheduler: { scheduledWorkItems.append($0) }
        )

        XCTAssertNoThrow(try controller.paste(text: "first"))
        XCTAssertNoThrow(try controller.paste(text: "second"))

        XCTAssertEqual(scheduledWorkItems.count, 2)
        XCTAssertTrue(scheduledWorkItems[0].isCancelled)
        XCTAssertFalse(scheduledWorkItems[1].isCancelled)
    }

    func testOverlappingPastesRestoreOriginalClipboard() {
        let pasteboard = NSPasteboard.withUniqueName()
        pasteboard.clearContents()
        pasteboard.setString("original", forType: .string)
        let clipboard = ClipboardController(pasteboard: pasteboard)
        var scheduledWorkItems: [DispatchWorkItem] = []
        let controller = PasteController(
            clipboard: clipboard,
            keyboardShortcutPoster: {},
            accessibilityPermissionChecker: { true },
            restoreScheduler: { scheduledWorkItems.append($0) }
        )

        XCTAssertNoThrow(try controller.paste(text: "first"))
        XCTAssertNoThrow(try controller.paste(text: "second"))
        scheduledWorkItems.last?.perform()

        XCTAssertEqual(pasteboard.string(forType: .string), "original")
    }

    func testPasteThrowsWhenAccessibilityPermissionIsMissing() {
        let pasteboard = NSPasteboard.withUniqueName()
        let clipboard = ClipboardController(pasteboard: pasteboard)
        var promptCallCount = 0
        let controller = PasteController(
            clipboard: clipboard,
            keyboardShortcutPoster: {},
            accessibilityPermissionChecker: { false },
            accessibilityPermissionPrompter: { promptCallCount += 1 },
            restoreScheduler: { _ in }
        )

        XCTAssertThrowsError(try controller.paste(text: "staged")) { error in
            XCTAssertEqual(
                error.localizedDescription,
                "SpeakMore 需要辅助功能权限，才能把整理后的文字粘贴到当前输入框。"
            )
        }
        XCTAssertEqual(promptCallCount, 1)
    }

    func testRevertLastPasteDeletesTrackedSpeakMoreTextOnce() throws {
        let pasteboard = NSPasteboard.withUniqueName()
        let clipboard = ClipboardController(pasteboard: pasteboard)
        var revertedTexts: [String] = []
        let controller = PasteController(
            clipboard: clipboard,
            keyboardShortcutPoster: {},
            accessibilityPermissionChecker: { true },
            lastInsertionReverter: { text in
                revertedTexts.append(text)
                return true
            },
            restoreScheduler: { _ in }
        )

        try controller.paste(text: "上一段 SpeakMore 插入的文字")

        XCTAssertTrue(try controller.revertLastPastedText())
        XCTAssertFalse(try controller.revertLastPastedText())
        XCTAssertEqual(revertedTexts, ["上一段 SpeakMore 插入的文字"])
    }

    func testRevertLastPastedSentenceDeletesTrackedSentencesOneByOne() throws {
        let pasteboard = NSPasteboard.withUniqueName()
        let clipboard = ClipboardController(pasteboard: pasteboard)
        var revertedTexts: [String] = []
        let controller = PasteController(
            clipboard: clipboard,
            keyboardShortcutPoster: {},
            accessibilityPermissionChecker: { true },
            lastInsertionReverter: { text in
                revertedTexts.append(text)
                return true
            },
            restoreScheduler: { _ in }
        )

        try controller.paste(text: "第一句话。第二句话。")

        XCTAssertTrue(try controller.revertLastPastedSentence())
        XCTAssertTrue(try controller.revertLastPastedSentence())
        XCTAssertFalse(try controller.revertLastPastedSentence())
        XCTAssertEqual(revertedTexts, ["第二句话。", "第一句话。"])
    }
}
