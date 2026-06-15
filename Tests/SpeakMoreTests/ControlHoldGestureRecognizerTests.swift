import XCTest
@testable import SpeakMore

final class ControlHoldGestureRecognizerTests: XCTestCase {
    func testLongControlHoldStartsAndReleaseFinishes() {
        var recognizer = ControlHoldGestureRecognizer()

        XCTAssertEqual(recognizer.modifierFlagsChanged(isOnlyControlPressed: true), [.scheduleStart])
        XCTAssertEqual(recognizer.longPressDelayElapsed(), [.start])
        XCTAssertEqual(recognizer.modifierFlagsChanged(isOnlyControlPressed: false), [.finish])
    }

    func testShortControlPressCancelsBeforeDelayWithoutStarting() {
        var recognizer = ControlHoldGestureRecognizer()

        XCTAssertEqual(recognizer.modifierFlagsChanged(isOnlyControlPressed: true), [.scheduleStart])
        XCTAssertEqual(recognizer.modifierFlagsChanged(isOnlyControlPressed: false), [.cancelScheduledStart])
        XCTAssertEqual(recognizer.longPressDelayElapsed(), [])
    }

    func testAnotherModifierFinishesActiveSession() {
        var recognizer = ControlHoldGestureRecognizer()

        XCTAssertEqual(recognizer.modifierFlagsChanged(isOnlyControlPressed: true), [.scheduleStart])
        XCTAssertEqual(recognizer.longPressDelayElapsed(), [.start])
        XCTAssertEqual(recognizer.modifierFlagsChanged(isOnlyControlPressed: false), [.finish])
        XCTAssertEqual(recognizer.longPressDelayElapsed(), [])
    }

    func testKeyDownDoesNotCancelActiveSession() {
        var recognizer = ControlHoldGestureRecognizer()

        XCTAssertEqual(recognizer.modifierFlagsChanged(isOnlyControlPressed: true), [.scheduleStart])
        XCTAssertEqual(recognizer.longPressDelayElapsed(), [.start])
        XCTAssertEqual(recognizer.keyDown(modeShortcut: nil), [])
        XCTAssertEqual(recognizer.modifierFlagsChanged(isOnlyControlPressed: false), [.finish])
    }

    func testModeShortcutSwitchesModeWhileActive() {
        var recognizer = ControlHoldGestureRecognizer()

        XCTAssertEqual(recognizer.modifierFlagsChanged(isOnlyControlPressed: true), [.scheduleStart])
        XCTAssertEqual(recognizer.longPressDelayElapsed(), [.start])
        XCTAssertEqual(recognizer.keyDown(modeShortcut: .translate), [.switchMode(.translate)])
        XCTAssertEqual(recognizer.modifierFlagsChanged(isOnlyControlPressed: false), [.finish])
    }

    func testRepeatedControlFlagEventsDoNotReschedule() {
        var recognizer = ControlHoldGestureRecognizer()

        XCTAssertEqual(recognizer.modifierFlagsChanged(isOnlyControlPressed: true), [.scheduleStart])
        XCTAssertEqual(recognizer.modifierFlagsChanged(isOnlyControlPressed: true), [])
    }
}
