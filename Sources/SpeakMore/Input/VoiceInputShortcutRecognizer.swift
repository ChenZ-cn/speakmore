import Foundation

enum VoiceInputShortcutEvent: Equatable {
    case flagsChanged(ShortcutModifiers)
    case keyDown(keyCode: UInt16, charactersIgnoringModifiers: String?, modifiers: ShortcutModifiers, isRepeat: Bool)
    case keyUp(keyCode: UInt16, modifiers: ShortcutModifiers)
}

struct VoiceInputShortcutRecognizer {
    private enum State {
        case idle
        case pendingStart
        case active
    }

    private let shortcut: VoiceInputShortcut
    private var state: State = .idle

    init(shortcut: VoiceInputShortcut) {
        self.shortcut = shortcut
    }

    mutating func handle(
        _ event: VoiceInputShortcutEvent,
        modeShortcut: SpeakMoreMode? = nil
    ) -> [ControlHoldGestureAction] {
        if state == .active, let modeShortcut, case .keyDown = event {
            return [.switchMode(modeShortcut)]
        }

        switch shortcut.trigger {
        case .pressAndHold:
            return handlePressAndHold(event)
        case .toggle:
            return handleToggle(event)
        }
    }

    mutating func longPressDelayElapsed() -> [ControlHoldGestureAction] {
        guard state == .pendingStart else {
            return []
        }

        state = .active
        return [.start]
    }

    private mutating func handlePressAndHold(_ event: VoiceInputShortcutEvent) -> [ControlHoldGestureAction] {
        switch event {
        case let .flagsChanged(modifiers):
            return handleModifierChangeForPressAndHold(modifiers)
        case let .keyDown(keyCode, _, modifiers, isRepeat):
            guard !isRepeat, !shortcut.binding.isModifierOnly else {
                return []
            }
            guard shortcut.binding.matches(keyCode: keyCode, modifiers: modifiers) else {
                return cancelPendingStartIfNeeded()
            }
            guard state == .idle else {
                return []
            }
            state = .pendingStart
            return [.scheduleStart]
        case let .keyUp(keyCode, modifiers):
            guard !shortcut.binding.isModifierOnly,
                  shortcut.binding.matches(keyCode: keyCode, modifiers: modifiers) else {
                return []
            }
            return releasePressAndHold()
        }
    }

    private mutating func handleToggle(_ event: VoiceInputShortcutEvent) -> [ControlHoldGestureAction] {
        guard case let .keyDown(keyCode, _, modifiers, isRepeat) = event,
              !isRepeat,
              shortcut.binding.matches(keyCode: keyCode, modifiers: modifiers) else {
            return []
        }

        switch state {
        case .idle, .pendingStart:
            state = .active
            return [.start]
        case .active:
            state = .idle
            return [.finish]
        }
    }

    private mutating func handleModifierChangeForPressAndHold(_ modifiers: ShortcutModifiers) -> [ControlHoldGestureAction] {
        if shortcut.binding.isModifierOnly {
            if shortcut.binding.matches(modifiers: modifiers) {
                guard state == .idle else {
                    return []
                }
                state = .pendingStart
                return [.scheduleStart]
            }
            return releasePressAndHold()
        }

        if state == .pendingStart || state == .active,
           !modifiers.isSuperset(of: shortcut.binding.modifiers) {
            return releasePressAndHold()
        }

        return []
    }

    private mutating func releasePressAndHold() -> [ControlHoldGestureAction] {
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

    private mutating func cancelPendingStartIfNeeded() -> [ControlHoldGestureAction] {
        guard state == .pendingStart else {
            return []
        }

        state = .idle
        return [.cancelScheduledStart]
    }
}
