import XCTest
@testable import SpeakMore

final class VoiceInputShortcutTests: XCTestCase {
    func testDefaultShortcutIsPressAndHoldControl() {
        XCTAssertEqual(VoiceInputShortcut.default.trigger, .pressAndHold)
        XCTAssertEqual(VoiceInputShortcut.default.binding.modifiers, .control)
        XCTAssertNil(VoiceInputShortcut.default.binding.keyCode)
        XCTAssertEqual(VoiceInputShortcut.default.displayTitle, "Control")
    }

    func testPressAndHoldModifierShortcutStartsAfterDelayAndFinishesOnRelease() {
        var recognizer = VoiceInputShortcutRecognizer(shortcut: .default)

        XCTAssertEqual(recognizer.handle(.flagsChanged(.control)), [.scheduleStart])
        XCTAssertEqual(recognizer.longPressDelayElapsed(), [.start])
        XCTAssertEqual(recognizer.handle(.flagsChanged([])), [.finish])
    }

    func testPressAndHoldKeyComboStartsAfterDelayAndFinishesOnKeyUp() {
        let shortcut = VoiceInputShortcut(
            trigger: .pressAndHold,
            binding: .init(modifiers: [.control], keyCode: 49, charactersIgnoringModifiers: " ")
        )
        var recognizer = VoiceInputShortcutRecognizer(shortcut: shortcut)

        XCTAssertEqual(recognizer.handle(.flagsChanged(.control)), [])
        XCTAssertEqual(
            recognizer.handle(.keyDown(keyCode: 49, charactersIgnoringModifiers: " ", modifiers: .control, isRepeat: false)),
            [.scheduleStart]
        )
        XCTAssertEqual(recognizer.longPressDelayElapsed(), [.start])
        XCTAssertEqual(recognizer.handle(.keyUp(keyCode: 49, modifiers: .control)), [.finish])
    }

    func testToggleShortcutStartsAndStopsOnRepeatedKeyDown() {
        let shortcut = VoiceInputShortcut(
            trigger: .toggle,
            binding: .init(modifiers: [.control, .option], keyCode: 49, charactersIgnoringModifiers: " ")
        )
        var recognizer = VoiceInputShortcutRecognizer(shortcut: shortcut)

        XCTAssertEqual(
            recognizer.handle(.keyDown(keyCode: 49, charactersIgnoringModifiers: " ", modifiers: [.control, .option], isRepeat: false)),
            [.start]
        )
        XCTAssertEqual(recognizer.handle(.keyUp(keyCode: 49, modifiers: [.control, .option])), [])
        XCTAssertEqual(
            recognizer.handle(.keyDown(keyCode: 49, charactersIgnoringModifiers: " ", modifiers: [.control, .option], isRepeat: false)),
            [.finish]
        )
    }

    func testModeShortcutStillWorksDuringCustomHoldSession() {
        let shortcut = VoiceInputShortcut(
            trigger: .pressAndHold,
            binding: .init(modifiers: [.control], keyCode: 49, charactersIgnoringModifiers: " ")
        )
        var recognizer = VoiceInputShortcutRecognizer(shortcut: shortcut)

        _ = recognizer.handle(.keyDown(keyCode: 49, charactersIgnoringModifiers: " ", modifiers: .control, isRepeat: false))
        _ = recognizer.longPressDelayElapsed()

        XCTAssertEqual(
            recognizer.handle(
                .keyDown(keyCode: 20, charactersIgnoringModifiers: "3", modifiers: .control, isRepeat: false),
                modeShortcut: .translate
            ),
            [.switchMode(.translate)]
        )
    }
}
