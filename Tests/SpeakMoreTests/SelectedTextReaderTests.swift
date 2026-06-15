import AppKit
import XCTest
@testable import SpeakMore

@MainActor
final class SelectedTextReaderTests: XCTestCase {
    func testReaderUsesAccessibilitySelectionBeforeClipboardFallback() async {
        var fallbackCallCount = 0
        let reader = SelectedTextReader(
            accessibilityReader: { "  辅助功能选区  " },
            clipboardFallbackReader: {
                fallbackCallCount += 1
                return "复制选区"
            }
        )

        let selectedText = await reader.readSelectedText()

        XCTAssertEqual(selectedText, "辅助功能选区")
        XCTAssertEqual(fallbackCallCount, 0)
    }

    func testReaderFallsBackToClipboardWhenAccessibilitySelectionIsEmpty() async {
        let reader = SelectedTextReader(
            accessibilityReader: { "   " },
            clipboardFallbackReader: { "  复制选区  " }
        )

        let selectedText = await reader.readSelectedText()

        XCTAssertEqual(selectedText, "复制选区")
    }

    func testClipboardFallbackRestoresOriginalClipboardAfterCopyingSelection() async {
        let pasteboard = NSPasteboard.withUniqueName()
        pasteboard.clearContents()
        pasteboard.setString("原剪贴板", forType: .string)
        let clipboard = ClipboardController(pasteboard: pasteboard)
        let fallback = ClipboardSelectedTextReader(
            clipboard: clipboard,
            copyShortcutPoster: {
                pasteboard.clearContents()
                pasteboard.setString("  复制出来的选区  ", forType: .string)
            },
            accessibilityPermissionChecker: { true },
            waitForClipboardUpdate: {}
        )

        let selectedText = await fallback.readSelectedText()

        XCTAssertEqual(selectedText, "复制出来的选区")
        XCTAssertEqual(pasteboard.string(forType: .string), "原剪贴板")
    }
}
