import AppKit
import XCTest
@testable import SpeakMore

final class HotKeyControllerTests: XCTestCase {
    func testDefaultLongPressDelayIsHalfSecond() {
        XCTAssertEqual(HotKeyController.defaultLongPressDelay, 0.5)
    }

    func testControlNumberModeShortcutsUseDisplayedOrder() {
        XCTAssertEqual(
            HotKeyController.modeShortcut(charactersIgnoringModifiers: "1", keyCode: 18, modifierFlags: .control),
            .auto
        )
        XCTAssertEqual(
            HotKeyController.modeShortcut(charactersIgnoringModifiers: "2", keyCode: 19, modifierFlags: .control),
            .dictate
        )
        XCTAssertEqual(
            HotKeyController.modeShortcut(charactersIgnoringModifiers: "3", keyCode: 20, modifierFlags: .control),
            .translate
        )
        XCTAssertEqual(
            HotKeyController.modeShortcut(charactersIgnoringModifiers: "4", keyCode: 21, modifierFlags: .control),
            .polish
        )
        XCTAssertEqual(
            HotKeyController.modeShortcut(charactersIgnoringModifiers: "5", keyCode: 23, modifierFlags: .control),
            .askSelectedText
        )
    }

    func testModeShortcutRequiresOnlyControlModifier() {
        XCTAssertNil(
            HotKeyController.modeShortcut(charactersIgnoringModifiers: "1", keyCode: 18, modifierFlags: [.control, .shift])
        )
        XCTAssertNil(
            HotKeyController.modeShortcut(charactersIgnoringModifiers: "1", keyCode: 18, modifierFlags: .command)
        )
    }
}
