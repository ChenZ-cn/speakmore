import Foundation

enum ControlHoldGestureAction: Equatable {
    case scheduleStart
    case cancelScheduledStart
    case start
    case finish
    case switchMode(SpeakMoreMode)
}

struct ControlHoldGestureRecognizer {
    private enum State {
        case idle
        case pendingStart
        case active
    }

    private var state: State = .idle

    mutating func modifierFlagsChanged(isOnlyControlPressed: Bool) -> [ControlHoldGestureAction] {
        if isOnlyControlPressed {
            switch state {
            case .idle:
                state = .pendingStart
                return [.scheduleStart]
            case .pendingStart, .active:
                return []
            }
        }

        switch state {
        case .idle:
            return []
        case .pendingStart:
            state = .idle
            return [.cancelScheduledStart]
        case .active:
            state = .idle
            return [.finish]
        }
    }

    mutating func longPressDelayElapsed() -> [ControlHoldGestureAction] {
        guard state == .pendingStart else {
            return []
        }

        state = .active
        return [.start]
    }

    mutating func keyDown(modeShortcut: SpeakMoreMode? = nil) -> [ControlHoldGestureAction] {
        if state == .active, let modeShortcut {
            return [.switchMode(modeShortcut)]
        }

        guard state == .pendingStart else {
            return []
        }

        state = .idle
        return [.cancelScheduledStart]
    }
}
